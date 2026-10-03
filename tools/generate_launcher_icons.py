"""
generate_launcher_icons.py
egg_day1.png (또는 egg_1.png)를 기반으로:
1. 레거시 런처 아이콘 5종 (다크 테마 배경 #1A1B22 적용)
2. 적응형 아이콘 foreground 5종 (투명 캔버스 중앙 배치)
을 생성합니다.
"""

import sys
from pathlib import Path

# Windows UTF-8 출력 보장
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

try:
    from PIL import Image
except ImportError:
    print("[ERROR] Pillow 라이브러리가 필요합니다: pip install Pillow")
    sys.exit(1)

SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent

# egg_day1.png 우선, 없으면 egg_1.png 사용
SOURCE_IMAGE = PROJECT_ROOT / "assets" / "images" / "eggs" / "egg_day1.png"
if not SOURCE_IMAGE.exists():
    SOURCE_IMAGE = PROJECT_ROOT / "assets" / "images" / "eggs" / "egg_1.png"

# 레거시 런처 아이콘 (48dp 기준)
MIPMAP_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

# 적응형 아이콘 foreground 규격 (108dp 기준)
FOREGROUND_SIZES = {
    "mipmap-mdpi": 108,
    "mipmap-hdpi": 162,
    "mipmap-xhdpi": 216,
    "mipmap-xxhdpi": 324,
    "mipmap-xxxhdpi": 432,
}

RES_BASE = PROJECT_ROOT / "android" / "app" / "src" / "main" / "res"


def make_launcher_icon(source_path: Path, size: int) -> Image.Image:
    """투명 배경 위에 알 이미지를 중앙에 배치하여 지정된 크기로 생성합니다 (알파 채널 유지)."""
    src = Image.open(source_path).convert("RGBA")

    # 가로/세로 비율 유지 (약간의 패딩)
    padding_ratio = 0.08
    inner_size = int(size * (1 - padding_ratio * 2))

    src.thumbnail((inner_size, inner_size), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))  # 완전 투명 배경
    offset_x = (size - src.width) // 2
    offset_y = (size - src.height) // 2
    canvas.paste(src, (offset_x, offset_y), src)

    return canvas


def make_foreground_icon(source_path: Path, size: int) -> Image.Image:
    """적응형 아이콘 규격(108dp): 투명 캔버스 중앙 safe zone(약 65%)에 알 배치"""
    src = Image.open(source_path).convert("RGBA")

    # safe zone (65%) 안에 맞추기
    inner_size = int(size * 0.65)
    src.thumbnail((inner_size, inner_size), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    offset_x = (size - src.width) // 2
    offset_y = (size - src.height) // 2
    canvas.paste(src, (offset_x, offset_y), src)

    return canvas


def main():
    if not SOURCE_IMAGE.exists():
        print(f"[ERROR] 소스 이미지가 없습니다: {SOURCE_IMAGE}")
        sys.exit(1)

    print(f"[INFO] 소스 이미지: {SOURCE_IMAGE} ({SOURCE_IMAGE.stat().st_size // 1024} KB)")

    for mipmap_dir, size in MIPMAP_SIZES.items():
        target_dir = RES_BASE / mipmap_dir
        if not target_dir.exists():
            continue

        # 1. ic_launcher.png (다크 배경)
        target_file = target_dir / "ic_launcher.png"
        icon = make_launcher_icon(SOURCE_IMAGE, size)
        icon.save(str(target_file), "PNG", optimize=True)

        # 2. ic_launcher_foreground.png (적응형 포그라운드)
        fg_size = FOREGROUND_SIZES[mipmap_dir]
        fg_file = target_dir / "ic_launcher_foreground.png"
        fg_icon = make_foreground_icon(SOURCE_IMAGE, fg_size)
        fg_icon.save(str(fg_file), "PNG", optimize=True)

        print(f"  [OK] {mipmap_dir}: ic_launcher.png({size}px) + ic_launcher_foreground.png({fg_size}px)")

    print("\n[DONE] 안드로이드 투명 배경 런처 & 적응형 아이콘 리소스 생성 완료!")


if __name__ == "__main__":
    main()

