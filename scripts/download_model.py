"""
Download Gemma 2B-IT (CPU int8) via kagglehub and push to connected Android device.

Prerequisites:
  1. pip install kagglehub
  2. Accept Gemma license on Kaggle: https://www.kaggle.com/models/google/gemma
  3. Authenticate: kagglehub.login() or set KAGGLE_USERNAME + KAGGLE_KEY env vars

Usage:
  python scripts/download_model.py
"""

import os
import shutil
import subprocess
import sys

try:
    import kagglehub
except ImportError:
    print("kagglehub not found. Run: pip install kagglehub")
    sys.exit(1)

MODEL_HANDLE = "google/gemma/tfLite/gemma-2b-it-cpu-int8/1"
TARGET_FILENAME = "model.bin"

# ── Step 1: Download via kagglehub ────────────────────────────────────────────
print(f"Downloading {MODEL_HANDLE} …")
print("(You will be prompted to authenticate if not already logged in)")
try:
    model_dir = kagglehub.model_download(MODEL_HANDLE)
except Exception as e:
    print(f"\nDownload failed: {e}")
    print("\nMake sure you have:")
    print("  1. A Kaggle account")
    print("  2. Accepted the Gemma license at https://www.kaggle.com/models/google/gemma")
    print("  3. Your API token in %USERPROFILE%\\.kaggle\\kaggle.json")
    sys.exit(1)

print(f"\nModel downloaded to: {model_dir}")

# ── Step 2: Locate the .bin file ──────────────────────────────────────────────
bin_file = None
for root, _, files in os.walk(model_dir):
    for f in files:
        if f.endswith(".bin"):
            bin_file = os.path.join(root, f)
            break
    if bin_file:
        break

if not bin_file:
    print("ERROR: No .bin file found in downloaded model directory.")
    print(f"Contents of {model_dir}:")
    for root, dirs, files in os.walk(model_dir):
        for f in files:
            print(f"  {os.path.join(root, f)}")
    sys.exit(1)

print(f"Found model file: {bin_file}")
size_mb = os.path.getsize(bin_file) / (1024 * 1024)
print(f"File size: {size_mb:.1f} MB")

# ── Step 3: Copy to project root as model.bin (for adb push convenience) ────
dest = os.path.join(os.path.dirname(os.path.dirname(__file__)), TARGET_FILENAME)
print(f"\nCopying to {dest} …")
shutil.copy2(bin_file, dest)
print("Copy done.")

# ── Step 4: Push to Android device via adb ───────────────────────────────────
print("\nChecking for connected Android devices …")
try:
    result = subprocess.run(
        ["adb", "devices"], capture_output=True, text=True, timeout=10
    )
    lines = [l.strip() for l in result.stdout.splitlines()
             if l.strip() and not l.startswith("List")]
    devices = [l for l in lines if "device" in l and "offline" not in l]
except FileNotFoundError:
    print("adb not found — skipping push. Push manually:")
    _print_manual_instructions(dest)
    sys.exit(0)
except Exception as e:
    print(f"adb error: {e}")
    devices = []


def _print_manual_instructions(src):
    pkg = "com.yourapp"  # placeholder
    print("\nManual adb push:")
    print(f'  adb push "{src}" /sdcard/Download/model.bin')
    print("Then copy it into the app's documents dir from the device, or use:")
    print(f'  adb shell "run-as {pkg} cp /sdcard/Download/model.bin /data/data/{pkg}/files/model.bin"')


if not devices:
    print("No device connected. Push the model manually once a device is attached:")
    print(f'  adb push "{dest}" /sdcard/Download/model.bin')
    print("\nDone! Model saved at:")
    print(f"  {dest}")
    sys.exit(0)

print(f"Found {len(devices)} device(s): {devices}")

# Push to /sdcard/Download/ (accessible without root)
sdcard_path = f"/sdcard/Download/{TARGET_FILENAME}"
print(f"\nPushing {dest} → {sdcard_path} …")
push = subprocess.run(
    ["adb", "push", dest, sdcard_path],
    capture_output=True, text=True, timeout=600,
)
if push.returncode != 0:
    print(f"adb push failed:\n{push.stderr}")
    sys.exit(1)

print(push.stdout.strip())
print("\n✅ Model pushed to device at:", sdcard_path)
print("\nNext steps:")
print("  The app will copy it automatically via path_provider when init() is")
print("  called from the Model Setup screen, OR you can copy it manually:")
print(f'    adb shell cp {sdcard_path} <app_documents_dir>/model.bin')
print("\nModel file also saved locally at:")
print(f"  {dest}")
