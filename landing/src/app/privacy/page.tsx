import type { Metadata } from "next";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";

export const metadata: Metadata = {
  title: "Privacy Policy — Lorescape",
  description:
    "How Lorescape collects, uses, and protects your information when you use our AI audio guide.",
};

export default function PrivacyPage() {
  return (
    <>
      <Navbar />
      <main className="bg-surface pt-32 pb-24 px-6">
        <article
          className="
            max-w-3xl mx-auto text-white/75 leading-relaxed
            [&_h2]:text-2xl [&_h2]:md:text-3xl [&_h2]:font-bold [&_h2]:text-white
            [&_h2]:tracking-tight [&_h2]:mt-12 [&_h2]:mb-4
            [&_p]:mb-4
            [&_ul]:mb-4 [&_ul]:space-y-2
            [&_ul>li]:list-disc [&_ul>li]:ml-6
            [&_ul>li>ul]:mt-2 [&_ul>li>ul]:mb-0
            [&_strong]:text-white [&_strong]:font-semibold
            [&_a]:text-primary [&_a]:underline [&_a]:underline-offset-2 hover:[&_a]:text-blue-400
          "
        >
          <header className="mb-10">
            <h1 className="text-4xl md:text-5xl font-black tracking-tight text-white mb-3">
              Privacy Policy
            </h1>
            <p className="text-sm uppercase tracking-widest text-white/40">
              Last Updated: 2026-04-23
            </p>
          </header>

          <p>
            <strong>Lorescape</strong> (&quot;the App&quot;) values your privacy.
            This Privacy Policy explains how we collect, use, disclose, and
            store your information.
          </p>

          <h2>1. Information We Collect</h2>
          <p>
            To provide location-based AI guide services, we may collect the
            following types of information:
          </p>
          <ul>
            <li>
              <strong>Location Data</strong>
              <ul>
                <li>
                  We request access to your precise location (GPS coordinates)
                  when you use the &quot;Explore&quot; or &quot;Guide&quot;
                  features.
                </li>
                <li>
                  <strong>Purpose</strong>: Strictly used to fetch nearby
                  historical landmarks and generate context-aware audio content
                  tailored to your location.
                </li>
                <li>
                  <strong>Storage</strong>: Location data is processed locally
                  or sent to the server for real-time queries only while the
                  App is in use. We <strong>do not</strong> store your
                  historical movement history on our servers, nor do we track
                  your location in the background.
                </li>
              </ul>
            </li>
            <li>
              <strong>Usage Data &amp; Journey of Exploration</strong>
              <ul>
                <li>
                  We record your interactions within the App, such as which
                  landmarks you have visited and the narration depth you
                  selected (Brief / Deep Dive).
                </li>
                <li>
                  <strong>Purpose</strong>: Used to build your personalized
                  &quot;Journey of Exploration,&quot; allowing you to review
                  your cultural journey.
                </li>
              </ul>
            </li>
            <li>
              <strong>Device Information</strong>
              <ul>
                <li>
                  We collect technical data related to your device, such as
                  device model, OS version, language settings, and unique
                  device identifiers (non-personally identifiable).
                </li>
                <li>
                  <strong>Purpose</strong>: Used to improve App stability, fix
                  bugs (Crash Logs), and optimize user experience.
                </li>
              </ul>
            </li>
          </ul>

          <h2>2. AI Technology &amp; Data Processing</h2>
          <p>
            The App utilizes advanced Artificial Intelligence technologies
            (e.g., OpenAI GPT or Google Gemini) to generate guide content.
          </p>
          <ul>
            <li>
              <strong>Data Transmission</strong>: When you start a guide,
              metadata related to the landmark (e.g., name, location tags) is
              sent to third-party AI service providers to generate the text.
            </li>
            <li>
              <strong>Privacy Protection</strong>: Data sent to AI services{" "}
              <strong>does not include</strong> your personally identifiable
              information (PII). We ensure that third-party providers do not
              use this data to train their models.
            </li>
          </ul>

          <h2>3. Third-Party Services &amp; Data Sharing</h2>
          <p>
            We do not share your personal data with third parties, except in
            the following cases:
          </p>
          <ul>
            <li>
              <strong>Service Providers</strong>: We use third-party cloud
              services (e.g., database hosting, AI APIs) to operate the App.
              These providers only access necessary data to perform specific
              tasks.
            </li>
            <li>
              <strong>Legal Requirements</strong>: We may disclose your
              information if required by law, legal process, litigation, or
              requests from public and governmental authorities.
            </li>
          </ul>

          <h2>4. Data Security &amp; Retention</h2>
          <ul>
            <li>
              We implement industry-standard security measures to protect your
              data.
            </li>
            <li>
              Your &quot;Journey of Exploration&quot; data is retained until
              you choose to delete your account.
            </li>
          </ul>

          <h2>5. Your Rights (Account Deletion)</h2>
          <p>
            You have the right to delete your account and all associated data
            at any time.
          </p>
          <ul>
            <li>
              <strong>How to delete</strong>: Go to{" "}
              <strong>[Settings]</strong> &gt; tap{" "}
              <strong>[Delete Account]</strong> within the App.
            </li>
            <li>
              Once confirmed, all your guide history and personal settings will
              be permanently removed from our servers and cannot be recovered.
            </li>
          </ul>

          <h2>6. Children&apos;s Privacy</h2>
          <p>
            The App is not intended for children under the age of 13, and we
            do not knowingly collect personal information from children.
          </p>

          <h2>7. Contact Us</h2>
          <p>
            If you have any questions regarding this Privacy Policy, please
            contact us at:
          </p>
          <ul>
            <li>
              <strong>Email</strong>:{" "}
              <a href="mailto:easylive1989@gmail.com">
                easylive1989@gmail.com
              </a>
            </li>
          </ul>

          {/* Divider */}
          <div
            className="my-16 flex items-center gap-4"
            aria-hidden="true"
          >
            <div className="flex-1 h-px bg-white/10" />
            <span className="text-xs uppercase tracking-widest text-white/40">
              繁體中文
            </span>
            <div className="flex-1 h-px bg-white/10" />
          </div>

          <header className="mb-10">
            <h1 className="text-4xl md:text-5xl font-black tracking-tight text-white mb-3">
              隱私權政策
            </h1>
            <p className="text-sm uppercase tracking-widest text-white/40">
              最後更新日期：2026-04-23
            </p>
          </header>

          <p>
            <strong>Lorescape</strong>（以下簡稱「本應用程式」）非常重視您的隱私權。本隱私權政策說明我們如何收集、使用、揭露、移轉及儲存您的資訊。請詳閱以下內容。
          </p>

          <h2>1. 我們收集的資訊</h2>
          <p>
            為了提供以位置為基礎的 AI 導覽服務，我們可能會收集以下類型的資訊：
          </p>
          <ul>
            <li>
              <strong>位置資訊 (Location Data)</strong>
              <ul>
                <li>
                  當您使用本應用程式的「探索」或「導覽」功能時，我們會請求存取您的精確位置（GPS 座標）。
                </li>
                <li>
                  <strong>用途</strong>：僅用於檢索您周邊的歷史景點資訊，以及生成與該地點相關的導覽內容。
                </li>
                <li>
                  <strong>儲存方式</strong>：位置資訊僅在 App 運作期間於本機處理或傳送至伺服器進行即時查詢，我們<strong>不會</strong>在伺服器上長期儲存您的歷史移動軌跡，亦不會在背景持續追蹤您的位置。
                </li>
              </ul>
            </li>
            <li>
              <strong>使用數據與探索歷程 (Usage Data &amp; Journey of Exploration)</strong>
              <ul>
                <li>
                  我們會記錄您在 App 內的互動行為，例如：您播放了哪些景點的導覽、選擇了哪種解說深度（摘要版／深度版）。
                </li>
                <li>
                  <strong>用途</strong>：用於建立您的個人化「探索歷程 (Journey of Exploration)」，讓您可以回顧旅程。
                </li>
              </ul>
            </li>
            <li>
              <strong>裝置資訊 (Device Information)</strong>
              <ul>
                <li>
                  我們會收集與您的裝置相關的技術數據，例如裝置型號、作業系統版本、語系設定及唯一裝置識別碼（非個人識別）。
                </li>
                <li>
                  <strong>用途</strong>：用於改善 App 穩定性、修復錯誤（Crash Logs）及優化使用者體驗。
                </li>
              </ul>
            </li>
          </ul>

          <h2>2. AI 技術與資料處理</h2>
          <p>
            本應用程式使用先進的人工智慧技術（如 OpenAI GPT 或 Google Gemini）來生成導覽內容。
          </p>
          <ul>
            <li>
              <strong>資料傳輸</strong>：當您點擊播放導覽時，與該景點相關的地理標籤與關鍵字會被傳送至第三方 AI 服務供應商以生成文本。
            </li>
            <li>
              <strong>隱私保護</strong>：傳送至 AI 服務的數據<strong>不包含</strong>您的個人識別資訊（如姓名、Email）。我們已要求第三方供應商不得將此數據用於訓練其模型。
            </li>
          </ul>

          <h2>3. 第三方服務與資料分享</h2>
          <p>
            除以下情況外，我們不會將您的個人資料分享給第三方：
          </p>
          <ul>
            <li>
              <strong>服務供應商</strong>：我們使用第三方雲端服務（如資料庫託管、AI 模型 API）來運作 App。這些供應商僅能在執行特定任務時存取必要數據。
            </li>
            <li>
              <strong>法律要求</strong>：若法律、法律程序、訴訟或政府機關要求，我們可能會揭露您的資訊。
            </li>
          </ul>

          <h2>4. 資料安全與保留</h2>
          <ul>
            <li>我們採取符合業界標準的安全措施來保護您的資料。</li>
            <li>您的「探索歷程」資料將保留至您主動刪除帳號為止。</li>
          </ul>

          <h2>5. 您的權利（帳號刪除）</h2>
          <p>您擁有隨時刪除帳號及所有相關數據的權利。</p>
          <ul>
            <li>
              <strong>操作方式</strong>：請在 App 中前往{" "}
              <strong>[設定] (Settings)</strong> ＞ 點選{" "}
              <strong>[刪除帳號] (Delete Account)</strong>。
            </li>
            <li>
              一旦執行刪除，您的所有導覽紀錄與個人設定將立即從我們的伺服器中永久移除，且無法復原。
            </li>
          </ul>

          <h2>6. 兒童隱私</h2>
          <p>
            本應用程式不以 13 歲以下兒童為目標客群，亦不會故意收集兒童的個人資訊。
          </p>

          <h2>7. 聯絡我們</h2>
          <p>若您對本隱私權政策有任何疑問，請透過以下方式聯繫我們：</p>
          <ul>
            <li>
              <strong>Email</strong>：{" "}
              <a href="mailto:easylive1989@gmail.com">
                easylive1989@gmail.com
              </a>
            </li>
          </ul>
        </article>
      </main>
      <Footer />
    </>
  );
}
