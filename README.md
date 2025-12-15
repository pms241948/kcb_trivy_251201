# SBOM Generator with Trivy

이 프로젝트는 **Trivy**를 사용하여 파일, 폴더, 그리고 **Docker 이미지**에 대한 **SBOM (Software Bill of Materials)**을 자동으로 생성해주는 도구입니다.

특히 **폐쇄망(Offline) 환경**에서도 동작하도록 설계되었으며, CycloneDX 포맷의 JSON 파일을 날짜별로 정리하여 저장합니다.

## ✨ 주요 기능

1.  **다양한 대상 스캔 지원**:
    *   **소스 코드 / 프로젝트 폴더**: Java, Python, Node.js, Go 등 모든 Trivy 지원 언어 자동 감지.
    *   **Docker 이미지 파일 (`.tar`)**: `docker save`로 저장된 이미지 파일을 건네주면 자동으로 인식하여 이미지 스캔 모드로 동작.
2.  **폐쇄망(Offline) 완벽 지원**:
    *   인터넷이 없는 서버에서도 실행 가능하도록 DB 및 이미지 다운로드 스크립트 제공.
    *   `--offline-scan` 옵션을 사용하여 외부 통신 차단.
3.  **자동화된 결과 관리**:
    *   `output/[YYYYMMDD]/` 폴더에 날짜별로 결과 자동 저장.

## 🚀 사용 방법

### 1. 사전 준비 (인터넷 가능한 PC에서)
폐쇄망 서버로 가져갈 자산을 다운로드합니다.

```bash
# Docker 이미지와 취약점 DB를 다운로드 및 압축합니다.
./prepare_offline.sh
```
생성된 `trivy_offline_assets` 폴더 안의 파일들과 `generate_sbom.sh`를 서버로 옮깁니다. 자세한 내용은 [OFFLINE_GUIDE.md](OFFLINE_GUIDE.md)를 참고하세요.

### 2. SBOM 생성 실행 (서버에서)

```bash
# 실행 권한 부여
chmod +x generate_sbom.sh

# 1) 프로젝트 소스 코드 폴더 스캔
./generate_sbom.sh /app/my-web-project

# 2) 단일 파일(jar, war 등) 스캔
./generate_sbom.sh /app/deploy/app.jar

# 3) Docker 이미지 파일(.tar) 스캔
./generate_sbom.sh /app/images/myapp-v1.tar
```

## 📂 프로젝트 구조

```text
.
├── generate_sbom.sh      # [메인] SBOM 생성 스크립트
├── prepare_offline.sh    # [준비] 오프라인용 자산 다운로드 스크립트
├── OFFLINE_GUIDE.md      # [문서] 오프라인 환경 가이드 (상세 절차)
├── test_sbom_generation.sh # [테스트] 기능 검증용 테스트 스크립트
└── README.md             # 프로젝트설명
```

## 🛠 지원 포맷 예시

본 도구는 Trivy가 지원하는 대부분의 포맷을 처리할 수 있습니다.

*   **Application Dependencies**: `pom.xml`, `package-lock.json`, `requirements.txt`, `Gemfile.lock`, `go.sum` 등
*   **OS Packages**: Alpine, RedHat, Debian 계열 (Docker 이미지 스캔 시)
*   **Archives**: `.tar` (Docker Image), `.jar`, `.war`
