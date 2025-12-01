# [폐쇄망] 오프라인 SBOM 자산 관리 시스템 - 사용자 가이드

본 가이드는 인터넷 연결이 없는 폐쇄망 환경에서 Trivy를 사용하여 SBOM을 생성하고 관리하는 방법을 설명합니다.

## 1. 환경 구축 (오프라인 준비)

폐쇄망에는 인터넷이 없으므로, 외부망(인터넷 가능)에서 Docker 이미지와 DB를 준비하여 반입해야 합니다.

### 1단계: 자산 다운로드 (외부망)
인터넷이 연결된 PC에서 수행합니다:

1.  **Trivy Docker 이미지 다운로드**:
    ```bash
    docker pull aquasec/trivy:latest
    ```

2.  **이미지를 파일로 저장 (tar)**:
    ```bash
    docker save -o trivy_latest.tar aquasec/trivy:latest
    ```

3.  **취약점 DB 준비 (선택 사항)**:
    스크립트는 기본적으로 `--offline-scan` 옵션을 사용하여 DB 업데이트를 건너뜁니다. 최신 취약점 정보가 필요하다면 외부망에서 DB를 캐싱한 후 `trivy-cache` 폴더를 통째로 반입해야 합니다.

### 2단계: 자산 반입 및 로드 (폐쇄망)
USB 또는 보안 파일 전송 시스템을 통해 `trivy_latest.tar` 파일을 폐쇄망 서버로 복사합니다.

1.  **Docker 이미지 로드**:
    ```bash
    docker load -i trivy_latest.tar
    ```

2.  **이미지 확인**:
    ```bash
    docker images
    # 목록에 'aquasec/trivy'가 보여야 합니다.
    ```

## 2. SBOM 생성 스크립트 사용법

`generate_sbom.sh` 스크립트는 단일 파일 또는 폴더 전체를 스캔하여 SBOM을 생성합니다.

### 사전 요구 사항
- **Docker**가 실행 중이어야 합니다.
- **Git Bash** (Windows) 또는 Linux 셸 환경이 필요합니다.

### 사용법
```bash
./generate_sbom.sh <대상_경로>
```

### 사용 예시

#### 예시 1: 단일 파일 스캔
특정 애플리케이션 파일(예: JAR, WAR) 하나에 대해 SBOM을 생성합니다.

```bash
./generate_sbom.sh ./my-app/app.jar
```
*결과*: `output/YYYYMMDD/YYYYMMDD_app.jar_SBOM.json`

#### 예시 2: 폴더 일괄 스캔 (배치 처리)
지정된 폴더 내의 **모든 파일**을 재귀적으로 찾아 각각 SBOM을 생성합니다.

```bash
./generate_sbom.sh ./projects/backend-repo
```
*결과*:
- `output/YYYYMMDD/YYYYMMDD_file1.jar_SBOM.json`
- `output/YYYYMMDD/YYYYMMDD_file2.war_SBOM.json`
- ...

## 3. 결과물 구조

생성된 SBOM 파일은 날짜별로 정리되어 이력 관리가 용이합니다.

```text
trivy/
├── generate_sbom.sh
├── trivy-cache/          # Trivy DB 캐시 (컨테이너 마운트용)
└── output/
    └── 20251201/         # 날짜별 폴더
        ├── 20251201_app.jar_SBOM.json
        └── 20251201_backend.war_SBOM.json
```

## 4. 문제 해결

- **Docker not found**: Docker가 실행 중인지 확인하세요 (`docker info`).
- **Permission denied**: 스크립트 실행 권한을 확인하세요 (`chmod +x generate_sbom.sh`).
- **경로 오류**: 절대 경로를 사용하거나 올바른 상대 경로인지 확인하세요.
