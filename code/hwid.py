# graciously written and skidded by fusion
# happy spoofing!!
import os
import re
import sys
import stat
import glob
import json
import shutil
import subprocess
import time
import random
import ctypes
import socket
import winreg
import tempfile
import traceback
import urllib.request
from datetime import datetime

REG_PATH_ADAPTER = r"SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
RUN_KEY = r"SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
INSTALLER_URL = "https://setup.rbxcdn.com/RobloxPlayerInstaller.exe"


class C:
    RESET = "\033[0m"
    DIM = "\033[2m"
    BOLD = "\033[1m"
    PURPLE = "\033[38;5;141m"
    VIOLET = "\033[38;5;99m"
    PINK = "\033[38;5;213m"
    CYAN = "\033[38;5;87m"
    GREEN = "\033[38;5;120m"
    YELLOW = "\033[38;5;221m"
    RED = "\033[38;5;203m"


TAGS = {
    "info": (C.CYAN, "info"),
    "ok": (C.GREEN, " ok "),
    "warn": (C.YELLOW, "warn"),
    "fail": (C.RED, "fail"),
}


def setup_console():
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass
    try:
        kernel32 = ctypes.windll.kernel32
        handle = kernel32.GetStdHandle(-11)
        mode = ctypes.c_ulong()
        kernel32.GetConsoleMode(handle, ctypes.byref(mode))
        kernel32.SetConsoleMode(handle, mode.value | 0x0004)
    except Exception:
        pass
    os.system("title VEIL")


def log(level, msg):
    color, label = TAGS[level]
    stamp = datetime.now().strftime("%H:%M:%S")
    print(f"{C.DIM}{stamp}{C.RESET} {color}[{label}]{C.RESET} {msg}")


def banner():
    width = 52
    rule = f"{C.VIOLET}{'─' * width}{C.RESET}"
    title = f"{C.BOLD}{C.PINK}V  E  I  L{C.RESET}"
    sub = f"{C.PURPLE}spoof  ·  restore  ·  reset  ·  reinstall{C.RESET}"
    print()
    print(rule)
    print(f"  {title}")
    print(f"  {sub}")
    print(rule)
    print()


def prompt(question, default=False):
    hint = "Y/n" if default else "y/N"
    answer = input(f"{C.PURPLE}?{C.RESET} {question} {C.DIM}({hint}){C.RESET} ").strip().lower()
    if answer == "":
        return default
    return answer == "y"


def pause():
    input(f"\n{C.DIM}press enter to close...{C.RESET}")


def is_admin():
    try:
        return bool(ctypes.windll.shell32.IsUserAnAdmin())
    except Exception:
        return False


def relaunch_as_admin():
    script = os.path.abspath(__file__)
    params = subprocess.list2cmdline([script] + sys.argv[1:])
    ret = ctypes.windll.shell32.ShellExecuteW(
        None, "runas", sys.executable, params, os.path.dirname(script), 1
    )
    if ret <= 32:
        log("fail", f"elevation failed or was cancelled (code {ret})")


def list_adapters():
    ps = (
        "Get-NetAdapter | "
        "Select-Object Name,InterfaceDescription,InterfaceGuid,Status,MacAddress,"
        "NdisPhysicalMedium,HardwareInterface | ConvertTo-Json -Compress"
    )
    out = subprocess.run(
        ["powershell", "-NoProfile", "-Command", ps],
        capture_output=True, text=True
    ).stdout.strip()
    if not out:
        return []
    data = json.loads(out)
    if isinstance(data, dict):
        data = [data]
    data.sort(key=lambda a: is_virtual(a))
    return data


def is_virtual(adapter):
    return not adapter.get("HardwareInterface", True)


def is_wifi(adapter):
    if adapter.get("NdisPhysicalMedium") == 9:
        return True
    text = f"{adapter.get('Name', '')} {adapter.get('InterfaceDescription', '')}"
    return bool(re.search(r"wi-?fi|wireless|802\.11|wlan", text, re.I))


def adapter_kind(adapter):
    if is_virtual(adapter):
        return "virtual"
    return "wifi" if is_wifi(adapter) else "wired"


def mac_is_custom(mac):
    try:
        return bool(int(mac[:2], 16) & 2)
    except (ValueError, TypeError):
        return False


def pick_adapters():
    try:
        adapters = list_adapters()
    except Exception as e:
        log("fail", f"adapter lookup error: {e}")
        return []

    if not adapters:
        log("warn", "no network adapters found")
        return []

    default = next(
        (
            i for i, a in enumerate(adapters)
            if adapter_kind(a) == "wifi" and a.get("Status") == "Up"
        ),
        None,
    )
    if default is None:
        default = next(
            (i for i, a in enumerate(adapters) if not is_virtual(a)), 0
        )

    print()
    for i, a in enumerate(adapters, 1):
        status = a.get("Status") or "?"
        scolor = C.GREEN if status == "Up" else C.DIM
        mac = a.get("MacAddress") or "no mac"
        custom = f"  {C.YELLOW}custom mac{C.RESET}" if mac_is_custom(mac) else ""
        print(
            f"  {C.PINK}{i}{C.RESET}  {a.get('Name')}  "
            f"{C.DIM}{a.get('InterfaceDescription')}{C.RESET}\n"
            f"     {scolor}{status}{C.RESET}  {C.DIM}{adapter_kind(a)}  {mac}{C.RESET}{custom}"
        )
    print()
    print(
        f"  {C.DIM}enter = default  ·  numbers like 1,3  ·  "
        f"'all' = every physical adapter{C.RESET}"
    )

    raw = input(
        f"{C.PURPLE}?{C.RESET} adapters {C.DIM}[{default + 1}]{C.RESET} "
    ).strip().lower()

    if raw == "":
        return [adapters[default]]

    if raw in ("a", "all"):
        return [a for a in adapters if not is_virtual(a)]

    picks = []
    for token in re.split(r"[,\s]+", raw):
        if token.isdigit() and 1 <= int(token) <= len(adapters):
            chosen = adapters[int(token) - 1]
            if chosen not in picks:
                picks.append(chosen)
        else:
            log("warn", f"invalid choice: {token}")
            return []
    return picks


def find_class_subkey(adapter):
    guid = (adapter.get("InterfaceGuid") or "").lower()
    desc = adapter.get("InterfaceDescription")
    fallback = None
    with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, REG_PATH_ADAPTER) as key:
        i = 0
        while True:
            try:
                subkey_name = winreg.EnumKey(key, i)
            except OSError:
                break
            i += 1
            try:
                with winreg.OpenKey(key, subkey_name) as subkey:
                    try:
                        instance = winreg.QueryValueEx(subkey, "NetCfgInstanceId")[0].lower()
                    except OSError:
                        instance = ""
                    if guid and instance == guid:
                        return subkey_name
                    try:
                        driver_desc = winreg.QueryValueEx(subkey, "DriverDesc")[0]
                    except OSError:
                        driver_desc = None
                    if fallback is None and driver_desc == desc:
                        fallback = subkey_name
            except OSError:
                continue
    return fallback


def get_wlan_profile(adapter_name):
    out = subprocess.run(
        ["netsh", "wlan", "show", "interfaces"], capture_output=True, text=True
    ).stdout
    for block in re.split(r"\r?\n\s*\r?\n", out):
        fields = {}
        for line in block.splitlines():
            if ":" in line:
                key, _, value = line.partition(":")
                fields.setdefault(key.strip(), value.strip())
        if fields.get("Name") == adapter_name and fields.get("Profile"):
            return fields["Profile"]

    safe = adapter_name.replace("'", "''")
    ps = (
        f"(Get-NetConnectionProfile -InterfaceAlias '{safe}' "
        "-ErrorAction SilentlyContinue).Name"
    )
    out = subprocess.run(
        ["powershell", "-NoProfile", "-Command", ps],
        capture_output=True, text=True
    ).stdout.strip()
    return out.splitlines()[0].strip() if out else None


def reconnect_wifi(adapter_name, profile):
    log("info", f"reconnecting to {C.PINK}{profile}{C.RESET}")
    cmd = f'netsh wlan connect name="{profile}" interface="{adapter_name}"'
    for _ in range(10):
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0 and "success" in result.stdout.lower():
            log("ok", "reconnect requested")
            return True
        time.sleep(2)
    log("warn", "could not reconnect automatically, connect manually")
    return False


def random_mac():
    first = (random.randint(0, 255) & 0xFE) | 0x02
    rest = [random.randint(0, 255) for _ in range(5)]
    return "".join(format(b, "02X") for b in [first] + rest)


def apply_mac(adapter, mac=None):
    adapter_name = adapter["Name"]
    kind = adapter_kind(adapter)
    restoring = mac is None

    log("info", f"{C.BOLD}{adapter_name}{C.RESET} {C.DIM}({kind}){C.RESET}")
    if kind == "virtual" and not restoring:
        log("warn", "virtual adapter, usually has no real mac so this likely does nothing")

    try:
        subkey_name = find_class_subkey(adapter)
    except Exception as e:
        log("fail", f"registry error: {e}")
        return False

    if not subkey_name:
        log("fail", "could not match adapter to a registry entry")
        return False

    profile = None
    if kind == "wifi":
        try:
            profile = get_wlan_profile(adapter_name)
        except Exception:
            profile = None
        if not profile:
            log("warn", "could not read current wifi network, reconnect manually if it drops")

    try:
        with winreg.OpenKey(
            winreg.HKEY_LOCAL_MACHINE,
            REG_PATH_ADAPTER + "\\" + subkey_name,
            0,
            winreg.KEY_SET_VALUE,
        ) as target_key:
            if restoring:
                try:
                    winreg.DeleteValue(target_key, "NetworkAddress")
                except FileNotFoundError:
                    log("info", "no custom mac set, already on the factory address")
                    return True
                log("info", "removed custom mac")
            else:
                log("info", f"setting {C.PINK}{mac}{C.RESET}")
                winreg.SetValueEx(target_key, "NetworkAddress", 0, winreg.REG_SZ, mac)

        log("info", "restarting adapter")
        subprocess.run(
            ["netsh", "interface", "set", "interface", adapter_name, "disable"],
            check=True, capture_output=True,
        )
        time.sleep(1)
        subprocess.run(
            ["netsh", "interface", "set", "interface", adapter_name, "enable"],
            check=True, capture_output=True,
        )

        if profile:
            time.sleep(2)
            reconnect_wifi(adapter_name, profile)

        log("ok", f"{adapter_name} done")
        return True

    except Exception as e:
        log("fail", f"error on {adapter_name}: {e}")
        return False


def run_spoof():
    log("info", "starting spoof (mac address)")

    adapters = pick_adapters()
    if not adapters:
        log("warn", "nothing selected")
        return

    print()
    done = sum(1 for a in adapters if apply_mac(a, random_mac()))
    log("ok", f"spoof complete: {done}/{len(adapters)} adapters (verify with getmac or ipconfig /all)")


def run_restore():
    log("info", "restoring original mac addresses")

    adapters = pick_adapters()
    if not adapters:
        log("warn", "nothing selected")
        return

    print()
    done = sum(1 for a in adapters if apply_mac(a))
    log("ok", f"restore complete: {done}/{len(adapters)} adapters (verify with getmac or ipconfig /all)")


ROBLOX_PROCESSES = [
    "RobloxPlayerBeta.exe",
    "RobloxPlayerLauncher.exe",
    "RobloxCrashHandler.exe",
    "RobloxPlayerInstaller.exe",
]


def _rm_handler(func, path, exc):
    try:
        os.chmod(path, stat.S_IWRITE)
        func(path)
    except OSError:
        pass


def wipe_dir(path):
    name = os.path.basename(os.path.normpath(path)).lower()
    if name != "roblox":
        log("fail", f"refusing to delete unexpected path: {path}")
        return False

    for attempt in range(3):
        if sys.version_info >= (3, 12):
            shutil.rmtree(path, onexc=_rm_handler)
        else:
            shutil.rmtree(path, onerror=_rm_handler)
        if not os.path.exists(path):
            return True
        time.sleep(1)
    return False


def reset_roblox():
    log("info", "starting roblox reset")

    log("info", "stopping roblox processes")
    for proc in ROBLOX_PROCESSES:
        try:
            subprocess.run(
                ["taskkill", "/IM", proc, "/F"], timeout=5, capture_output=True
            )
        except Exception as e:
            log("warn", f"taskkill error for {proc}: {e}")
    time.sleep(1)

    temp = os.environ.get("TEMP", "")
    candidates = [
        os.path.join(os.environ.get("LOCALAPPDATA", ""), "Roblox"),
        r"C:\Program Files (x86)\Roblox",
        r"C:\Program Files\Roblox",
        os.path.join(temp, "Roblox"),
    ]
    targets = []
    for c in candidates:
        if c and os.path.isdir(c) and c not in targets:
            targets.append(c)

    if not targets:
        log("info", "no roblox files found, nothing to wipe")

    for target in targets:
        try:
            if wipe_dir(target):
                log("ok", f"removed {target}")
            else:
                log("warn", f"some files in {target} could not be removed")
        except Exception as e:
            log("fail", f"could not remove {target}: {e}")

    if temp:
        for leftover in glob.glob(os.path.join(temp, "RobloxPlayerInstaller*.exe")):
            try:
                os.remove(leftover)
                log("ok", f"removed {leftover}")
            except OSError:
                pass

    try:
        with winreg.OpenKey(
            winreg.HKEY_LOCAL_MACHINE, RUN_KEY, 0, winreg.KEY_SET_VALUE
        ) as key:
            winreg.DeleteValue(key, "RobloxRickRoll")
        log("ok", "removed startup entry")
    except FileNotFoundError:
        log("info", "startup entry not present")
    except Exception as e:
        log("fail", f"registry error: {e}")


def verify_signature(path):
    ps = (
        f"$s = Get-AuthenticodeSignature -LiteralPath '{path}'; "
        "[pscustomobject]@{Status=[string]$s.Status; "
        "Subject=[string]$s.SignerCertificate.Subject} | ConvertTo-Json"
    )
    out = subprocess.run(
        ["powershell", "-NoProfile", "-Command", ps],
        capture_output=True, text=True
    ).stdout.strip()
    if not out:
        return False
    data = json.loads(out)
    return data.get("Status") == "Valid" and "roblox" in data.get("Subject", "").lower()


def wait_for_network(host="setup.rbxcdn.com", port=443, timeout=90):
    log("info", "waiting for network")
    end = time.time() + timeout
    while time.time() < end:
        try:
            with socket.create_connection((host, port), timeout=5):
                return True
        except OSError:
            time.sleep(2)
    return False


def download_installer(dest, attempts=4):
    for n in range(1, attempts + 1):
        try:
            req = urllib.request.Request(INSTALLER_URL, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=30) as resp, open(dest, "wb") as f:
                shutil.copyfileobj(resp, f)
            return True
        except Exception as e:
            log("warn", f"download attempt {n}/{attempts} failed: {e}")
            time.sleep(4)
    return False


def install_roblox():
    if not wait_for_network():
        log("fail", "could not reach roblox servers, check your connection and run again")
        return

    log("info", "downloading roblox installer")
    dest = os.path.join(tempfile.gettempdir(), "RobloxPlayerInstaller.exe")

    if not download_installer(dest):
        log("fail", "download failed after retries")
        return

    log("info", "verifying installer signature")
    try:
        valid = verify_signature(dest)
    except Exception as e:
        log("fail", f"signature check error: {e}")
        valid = False

    if not valid:
        log("fail", "signature is not a valid roblox signature, not running it")
        try:
            os.remove(dest)
        except OSError:
            pass
        return

    log("ok", "signature valid")
    log("info", "running installer, wait for it to finish")
    try:
        subprocess.run([dest], check=False)
        log("ok", "installer finished")
    except Exception as e:
        log("fail", f"could not run installer: {e}")
    finally:
        try:
            os.remove(dest)
        except OSError:
            pass


def choose_mode():
    print(f"  {C.PINK}1{C.RESET}  spoof mac  {C.DIM}+ wipe roblox + reinstall{C.RESET}")
    print(f"  {C.PINK}2{C.RESET}  restore original mac")
    print(f"  {C.PINK}q{C.RESET}  quit")
    print()
    choice = input(f"{C.PURPLE}?{C.RESET} mode ").strip().lower()
    return {"1": "spoof", "2": "restore"}.get(choice)


def main():
    setup_console()
    banner()

    if not is_admin():
        log("warn", "admin rights required, relaunching elevated")
        relaunch_as_admin()
        return

    mode = choose_mode()
    if not mode:
        log("info", "cancelled")
        pause()
        return

    if mode == "spoof":
        run_spoof()
        reset_roblox()
        if prompt("reinstall roblox from roblox.com now?", default=True):
            install_roblox()
    else:
        run_restore()

    print()
    log("ok", "all done")
    pause()


if __name__ == "__main__":
    try:
        main()
    except Exception:
        traceback.print_exc()
        input("\ncrashed. press enter to close...")
