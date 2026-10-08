#!/usr/bin/env python3
"""
BSG Google Camera (MGC 9.6xx) Automated Downloader
Scrapes https://www.celsoazevedo.com/files/android/google-camera/dev-bsg/
to discover and download the latest MGC 9.6xx ENG APK (com.google.android.GoogleCameraEng).
"""

import os
import sys
import re
import time
import shutil
import urllib.request
import urllib.parse

BASE_DEV_URL = "https://www.celsoazevedo.com/files/android/google-camera/dev-bsg/"
FALLBACK_APK_URL = "https://1-dontsharethislink.celsoazevedo.com/file/filesc/MGC_9.6.080_V51_ENG.apk"
FALLBACK_FILENAME = "MGC_9.6.080_V51_ENG.apk"
FALLBACK_VERSION = "9.6.080_V51"

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Referer': BASE_DEV_URL,
}

def get_latest_mgc_96_info():
    """
    Scrapes the BSG developer portal to locate the newest MGC 9.6 release page
    and returns (download_url, filename, version_name).
    """
    print(f"[INFO] Querying BSG portal: {BASE_DEV_URL}")
    try:
        req = urllib.request.Request(BASE_DEV_URL, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=15) as resp:
            html = resp.read().decode('utf-8', errors='ignore')

        # Find releases matching MGC_9.6...
        matches = re.findall(r'<a\s+[^>]*href=["\']([^"\']+)["\'][^>]*>(MGC_9\.6[0-9a-zA-Z._]*)</a>', html)
        if not matches:
            matches = re.findall(r'href=["\']([^"\']*dev-bsg/f/dl\d+[^"\']*)["\'][^>]*>(?:<[^>]+>)*\s*(MGC_9\.6[0-9a-zA-Z._]*)', html)

        if not matches:
            print("[WARNING] Could not parse latest 9.6 release from BSG index. Using fallback.")
            return FALLBACK_APK_URL, FALLBACK_FILENAME, FALLBACK_VERSION

        rel_url, ver_name = matches[0]
        release_page_url = urllib.parse.urljoin(BASE_DEV_URL, rel_url)
        print(f"[INFO] Found latest MGC 9.6 release: {ver_name} -> {release_page_url}")

        # Fetch release subpage
        req_sub = urllib.request.Request(release_page_url, headers=HEADERS)
        with urllib.request.urlopen(req_sub, timeout=15) as resp_sub:
            sub_html = resp_sub.read().decode('utf-8', errors='ignore')

        # Find _ENG.apk download link
        eng_matches = re.findall(r'href=["\']([^"\']+MGC_9\.6[^\'"]*_ENG\.apk)["\']', sub_html)
        if not eng_matches:
            eng_matches = re.findall(r'href=["\']([^"\']+MGC[^\'"]*_ENG\.apk)["\']', sub_html)
        if not eng_matches:
            eng_matches = re.findall(r'href=["\']([^"\']+_ENG\.apk)["\']', sub_html)

        if not eng_matches:
            print(f"[WARNING] Could not locate _ENG.apk on {release_page_url}. Using fallback.")
            return FALLBACK_APK_URL, FALLBACK_FILENAME, FALLBACK_VERSION

        dl_url = urllib.parse.urljoin(release_page_url, eng_matches[0])
        parsed_path = urllib.parse.urlparse(dl_url).path
        filename = os.path.basename(parsed_path) or f"{ver_name}_ENG.apk"
        return dl_url, filename, ver_name

    except Exception as e:
        print(f"[WARNING] Web query failed: {e}. Falling back to default URL.")
        return FALLBACK_APK_URL, FALLBACK_FILENAME, FALLBACK_VERSION

def download_file_with_progress(url, dest_path):
    """
    Downloads file from URL to dest_path with download speed & progress display.
    Uses .part temporary file during download.
    """
    tmp_path = dest_path + ".part"
    if os.path.exists(tmp_path):
        os.remove(tmp_path)

    req = urllib.request.Request(url, headers=HEADERS)
    print(f"[INFO] Downloading: {url}")
    print(f"[INFO] Saving to: {dest_path}")

    start_time = time.time()
    last_print = 0

    with urllib.request.urlopen(req, timeout=30) as resp, open(tmp_path, 'wb') as out_f:
        total_size = int(resp.headers.get('Content-Length', 0))
        downloaded = 0
        chunk_size = 1024 * 1024  # 1 MB chunk

        while True:
            chunk = resp.read(chunk_size)
            if not chunk:
                break
            out_f.write(chunk)
            downloaded += len(chunk)

            now = time.time()
            if now - last_print > 0.5 or (total_size and downloaded == total_size):
                last_print = now
                elapsed = max(now - start_time, 0.001)
                speed_mb = (downloaded / (1024 * 1024)) / elapsed
                if total_size:
                    percent = (downloaded / total_size) * 100
                    total_mb = total_size / (1024 * 1024)
                    dl_mb = downloaded / (1024 * 1024)
                    sys.stdout.write(f"\r  [{percent:5.1f}%] {dl_mb:.1f} MB / {total_mb:.1f} MB ({speed_mb:.2f} MB/s)")
                else:
                    dl_mb = downloaded / (1024 * 1024)
                    sys.stdout.write(f"\r  {dl_mb:.1f} MB downloaded ({speed_mb:.2f} MB/s)")
                sys.stdout.flush()

    print()
    if os.path.exists(dest_path):
        os.remove(dest_path)
    os.rename(tmp_path, dest_path)
    print(f"[SUCCESS] Download completed: {dest_path} ({os.path.getsize(dest_path):,} bytes)")

def is_valid_apk(file_path):
    """Checks if a file exists and is a valid non-empty APK (> 50MB for MGC GCam)."""
    if not os.path.isfile(file_path):
        return False
    size = os.path.getsize(file_path)
    # The MGC 9.6 APK is ~320-350MB; Git LFS pointer is ~134 bytes.
    if size < 50 * 1024 * 1024:
        return False
    return True

def ensure_gcam_apk(target_dir=None, force=False):
    """
    Ensures that a valid BSG MGC 9.6xx APK is present in target_dir (default: <base_dir>/apk).
    If missing or invalid:
      1. Checks %USERPROFILE%/Downloads/
      2. If not found, scrapes latest release and downloads from BSG.
    Returns the absolute path to the valid APK.
    """
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    if target_dir is None:
        target_dir = os.path.join(base_dir, 'apk')
    os.makedirs(target_dir, exist_ok=True)

    dl_url, filename, ver_name = get_latest_mgc_96_info()
    dest_path = os.path.join(target_dir, filename)

    # 1. If already valid and not force
    if not force and is_valid_apk(dest_path):
        print(f"[OK] Valid GCam APK already exists: {dest_path} ({os.path.getsize(dest_path):,} bytes)")
        return dest_path

    # Check for any other existing valid MGC 9.6 APK in target_dir
    if not force:
        for f in os.listdir(target_dir):
            if f.endswith('.apk') and ('MGC_9.6' in f or 'MGC' in f) and 'ENG' in f:
                cand = os.path.join(target_dir, f)
                if is_valid_apk(cand):
                    print(f"[OK] Found existing valid GCam APK: {cand} ({os.path.getsize(cand):,} bytes)")
                    return cand

    # 2. Check %USERPROFILE%/Downloads
    user_downloads = os.path.join(os.path.expanduser('~'), 'Downloads')
    download_cands = [
        os.path.join(user_downloads, filename),
        os.path.join(user_downloads, 'MGC_9.6.080_V51_ENG.apk'),
    ]
    if os.path.isdir(user_downloads):
        for f in os.listdir(user_downloads):
            if f.endswith('.apk') and 'MGC' in f and 'ENG' in f:
                download_cands.append(os.path.join(user_downloads, f))

    if not force:
        for cand in download_cands:
            if is_valid_apk(cand):
                print(f"[INFO] Found local GCam APK in Downloads: {cand}")
                print(f"[INFO] Copying to {dest_path}...")
                shutil.copy2(cand, dest_path)
                return dest_path

    # 3. Download from website
    print(f"[INFO] Downloading latest BSG MGC 9.6 APK ({ver_name})...")
    download_file_with_progress(dl_url, dest_path)
    return dest_path

if __name__ == '__main__':
    force_download = '--force' in sys.argv
    check_only = '--check' in sys.argv

    if check_only:
        url, fn, ver = get_latest_mgc_96_info()
        print(f"Latest Version : {ver}")
        print(f"Filename       : {fn}")
        print(f"URL            : {url}")
        sys.exit(0)

    apk_path = ensure_gcam_apk(force=force_download)
    print(f"\n[DONE] GCam APK ready at: {apk_path}")
