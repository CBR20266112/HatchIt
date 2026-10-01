import os
import zipfile
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
MASCOTS_DIR = BASE_DIR / "assets" / "images" / "mascots"
DIST_DIR = BASE_DIR / "dist_packs"

def pack_mascots():
    DIST_DIR.mkdir(parents=True, exist_ok=True)
    print(f"=== 16종 마스코트 독립 압축팩 생성 시작 ===")
    print(f"소스 디렉토리: {MASCOTS_DIR}")
    print(f"출력 디렉토리: {DIST_DIR}\n")

    summary = []

    for species_id in range(1, 17):
        species_dir = MASCOTS_DIR / str(species_id)
        if not species_dir.exists():
            print(f"[경고] ID {species_id} 디렉토리가 존재하지 않습니다: {species_dir}")
            continue

        png_files = sorted([f for f in species_dir.iterdir() if f.is_file() and f.suffix.lower() == ".png"])
        zip_path = DIST_DIR / f"mascot_{species_id}.zip"

        with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as zipf:
            for file in png_files:
                zipf.write(file, arcname=file.name)

        size_bytes = zip_path.stat().st_size
        size_mb = size_bytes / (1024 * 1024)

        summary.append({
            "id": species_id,
            "filename": zip_path.name,
            "file_count": len(png_files),
            "size_mb": size_mb,
            "sample_files": [f.name for f in png_files[:5]]
        })

    print(f"{'ID':<4} | {'압축 파일명':<16} | {'파일 수':<6} | {'용량(MB)':<10} | {'샘플 파일'}")
    print("-" * 75)
    total_size = 0.0
    for s in summary:
        sample_str = ", ".join(s["sample_files"]) + " ..."
        print(f"{s['id']:<4} | {s['filename']:<16} | {s['file_count']:<6} | {s['size_mb']:>8.2f} MB | {sample_str}")
        total_size += s["size_mb"]

    print("-" * 75)
    print(f"총 {len(summary)}개 마스코트 압축팩 생성 완료! 총 용량: {total_size:.2f} MB")

if __name__ == "__main__":
    pack_mascots()
