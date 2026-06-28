# Google Drive 檔案上傳設定教學

本文說明如何設定 Google Cloud Credentials，以供專案中的 `scripts/upload_to_drive.py` 腳本將檔案上傳至指定 Google Drive 資料夾。

---

## 1. 前置準備

### 1-1. 啟用 Google Drive API

1. 登入 [Google Cloud Console](https://console.cloud.google.com/)。
2. 選擇你目前與專案綁定的 Google Cloud Project。
3. 在上方搜尋欄輸入 `Google Drive API` 並選擇它。
4. 點選 **啟用 (Enable)**。

### 1-2. 建立服務帳戶 (Service Account)

1. 前往 **IAM 與管理 (IAM & Admin)** → **服務帳戶 (Service Accounts)**。
2. 點選頁面頂部的 **建立服務帳戶 (Create Service Account)**。
3. 填入服務帳戶名稱（例如：`google-drive-uploader`），然後點選 **建立並繼續**。
4. 專案角色權限可跳過（無需設定專案級角色），直接點選 **完成**。

### 1-3. 建立並下載 JSON 金鑰

1. 在服務帳戶列表中，點選剛建立的服務帳戶。
2. 切換至 **金鑰 (Keys)** 分頁。
3. 點選 **新增金鑰 (Add Key)** → **建立新金鑰 (Create new key)**。
4. 選擇 **JSON** 格式，點選 **建立 (Create)**。
5. 下載的 JSON 檔案即為你的憑證金鑰，請妥善保管。

> ⚠️ **安全警告：** 請勿將此 JSON 憑證金鑰提交至 GitHub 中。本專案已在 `.gitignore` 設定排除，但仍請務必注意。

---

## 2. 憑證設定與存放位置

`scripts/upload_to_drive.py` 腳本支援多種憑證載入機制。建議使用以下 **方法一**，將金鑰固定存放在專案目錄中。

### 方法一：預設檔名與路徑（最推薦）
將下載的 JSON 金鑰重新命名為 **`service-account.json`**，並放置在以下任一位置。腳本執行時會自動偵測並讀取：
1. 專案根目錄：`instant_explore/service-account.json`
2. 後端根目錄：`instant_explore/backend/service-account.json`

### 方法二：環境變數設定
您可以設定環境變數 `GOOGLE_APPLICATION_CREDENTIALS` 指向您的 JSON 金鑰絕對路徑：
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/service-account.json"
```

### 方法三：使用 Google 應用程式預設憑證 (ADC)
在本地已安裝 [Google Cloud SDK (gcloud)](https://cloud.google.com/sdk) 的開發環境中，直接於終端機執行：
```bash
gcloud auth application-default login
```
此時腳本將自動使用您的個人 Google 帳號憑證進行上傳（需確認您的 Google 帳號對該 Cloud Project 有 API 呼叫權限）。

### 方法四：執行腳本時手動指定參數
在執行腳本時，使用 `--credentials` 參數指定金鑰位置：
```bash
python scripts/upload_to_drive.py <file_path> --credentials /path/to/your/service-account.json
```

---

## 3. Google Drive 目標資料夾共用設定（關鍵步驟）

**由於 Service Account 是一個獨立的虛擬身分，預設無法存取您的個人雲端硬碟。** 為了能夠讓腳本成功將檔案上傳至您的個人 Google Drive 資料夾，必須進行以下共享授權設定：

1. 開啟金鑰的 JSON 檔案，找到裡面的 `"client_email"`，複製其 email 網址。
   *(格式通常為：`google-drive-uploader@<PROJECT_ID>.iam.gserviceaccount.com`)*
2. 在您的瀏覽器中開啟 [Google Drive](https://drive.google.com/)，找到您打算存放上傳檔案的目標資料夾。
3. 在資料夾上點選右鍵 → **共用 (Share)** → **共用**。
4. 在「新增使用者或群組」的輸入框中，貼上剛才複製的 **Service Account Email**。
5. 將權限角色設為 **「編輯者 (Editor)」**（不可為唯讀，否則會發生寫入權限錯誤）。
6. 取消勾選「通知使用者」（因為此帳號沒有收件匣），點選 **傳送 (Send) / 共用**。

---

## 4. 腳本使用說明

設定完成後，即可使用以下指令進行上傳測試：

### 基本執行
```bash
python scripts/upload_to_drive.py <本地檔案路徑> --folder-id <Google_Drive_資料夾_ID>
```

*   **`<本地檔案路徑>`**：您要上傳的本地檔案路徑（如 `assets/example.jpg`）。
*   **`<Google_Drive_資料夾_ID>`**：可以在瀏覽器開啟 Google Drive 目標資料夾時，從網址列的最後一段取得。
    *(例如網址為 `https://drive.google.com/drive/folders/1aBcDeFgHiJkLmNoPqRsTuVwXyZ`，則資料夾 ID 為 `1aBcDeFgHiJkLmNoPqRsTuVwXyZ`)*

### 可用參數一覽

| 參數 | 說明 | 範例 |
|------|------|------|
| `--folder-id` | Google Drive 的目標資料夾 ID。若未提供，檔案將會上傳至該 Service Account 的雲端硬碟根目錄。 | `--folder-id 1aBcDeFgHi...` |
| `--name` | 指定檔案上傳至雲端後的自訂名稱。若未提供，則預設使用本地檔案名稱。 | `--name uploaded_image.jpg` |
| `--mime-type` | 手動指定上傳檔案的 MIME type。若未提供，腳本會自動根據副檔名進行判定。 | `--mime-type image/jpeg` |
| `--credentials` | 手動指定 Google Service Account JSON 金鑰的路徑。 | `--credentials ./my-key.json` |

### 執行成功回傳範例

如果設定與上傳皆成功，終端機將會輸出如下資訊：

```text
Initializing credentials...
Loading default credentials from project root: /Users/paulwu/Documents/Github/instant_explore/service-account.json
Uploading file to Google Drive: test.txt
Detected MIME type: text/plain
Target Folder ID: 1aBcDeFgHiJkLmNoPqRsTuVwXyZ

=== Upload Successful ===
File Name: test.txt
File ID: 1Z2y3X4w5V6u7T...
Web View Link: https://drive.google.com/file/d/1Z2y3X4w5V6u7T.../view?usp=drivesdk
```

---

## 5. 相關檔案與工具

| 檔案/目錄 | 說明 |
|------|------|
| [upload_to_drive.py](file:///Users/paulwu/Documents/Github/instant_explore/scripts/upload_to_drive.py) | Google Drive 檔案上傳的 Python 執行腳本。 |
| `.gitignore` | 專案 Git 排除設定檔（內已包含 `service-account.json` 以防金鑰被提交）。 |
