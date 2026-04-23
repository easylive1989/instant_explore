import type { Metadata } from "next";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";

export const metadata: Metadata = {
  title: "Support — Lorescape",
  description:
    "Contact Lorescape support or browse frequently asked questions about the AI audio guide.",
};

export default function SupportPage() {
  return (
    <>
      <Navbar />
      <main className="bg-surface pt-32 pb-24 px-6">
        <article
          className="
            max-w-3xl mx-auto text-white/75 leading-relaxed
            [&_h2]:text-2xl [&_h2]:font-bold [&_h2]:text-white [&_h2]:tracking-tight [&_h2]:mb-4
            [&_p]:mb-4
            [&_strong]:text-white [&_strong]:font-semibold
            [&_a]:text-primary [&_a]:underline [&_a]:underline-offset-2 hover:[&_a]:text-blue-400
          "
        >
          <header className="mb-10">
            <h1 className="text-4xl md:text-5xl font-black tracking-tight text-white mb-3">
              👋 Welcome to Lorescape Support
            </h1>
          </header>

          <p>
            Thank you for choosing <strong>Lorescape</strong>. We are dedicated
            to providing you with the most immersive AI audio guide experience.
            If you have any questions, feedback, or need to report a bug,
            please feel free to reach out to us.
          </p>

          {/* Contact callout */}
          <div className="glass-card rounded-2xl p-6 my-8 border-l-4 border-emerald-400/60">
            <div className="flex items-start gap-3">
              <span className="text-2xl leading-none" aria-hidden="true">
                📧
              </span>
              <div className="flex-1 min-w-0">
                <h2>Contact Us</h2>
                <ul className="space-y-2 list-disc ml-6">
                  <li>
                    <strong>Support Email</strong>:{" "}
                    <a href="mailto:easylive1989@gmail.com">
                      easylive1989@gmail.com
                    </a>
                  </li>
                  <li>
                    <strong>Response Time</strong>: We typically respond within
                    24–48 hours.
                  </li>
                </ul>
              </div>
            </div>
          </div>

          {/* FAQ callout */}
          <div className="glass-card rounded-2xl p-6 my-8 border-l-4 border-amber-400/60">
            <div className="flex items-start gap-3">
              <span className="text-2xl leading-none" aria-hidden="true">
                ❓
              </span>
              <div className="flex-1 min-w-0">
                <h2>Frequently Asked Questions</h2>

                <p>
                  <strong>Q: Why can&apos;t I hear the audio guide?</strong>
                </p>
                <p>
                  A: Please check if your device is in silent mode and ensure
                  you have granted audio permissions to the app. We recommend
                  using headphones for the best immersive experience.
                </p>

                <p>
                  <strong>Q: Is an internet connection required?</strong>
                </p>
                <p>
                  A: Yes. An active internet connection is required to
                  generate real-time historical insights based on your
                  location.
                </p>

                <p>
                  <strong>Q: Is my location being tracked?</strong>
                </p>
                <p>
                  A: <strong>Lorescape</strong> only accesses your location
                  when you use the &quot;Explore&quot; feature to find nearby
                  points of interest. We do not track your location in the
                  background. Your privacy is our priority.
                </p>

                <p>
                  <strong>
                    Q: Is the historical information provided by AI 100%
                    accurate?
                  </strong>
                </p>
                <p>
                  A: Our AI persona acts as a &quot;Rigorous Historian&quot;
                  and strives to provide fact-based information. However,
                  AI-generated content may occasionally contain errors. If you
                  spot any inaccuracies, please let us know.
                </p>

                <p>
                  <strong>Q: How do I delete my account and data?</strong>
                </p>
                <p>
                  A: You can request account deletion at any time. Go to{" "}
                  <strong>[Settings]</strong> &gt;{" "}
                  <strong>[Delete Account]</strong> within the app. All your
                  personal data and &quot;Knowledge Passport&quot; records
                  will be permanently deleted immediately. You can also
                  contact us via email for assistance.
                </p>
              </div>
            </div>
          </div>

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
              👋 歡迎來到 Lorescape 支援中心
            </h1>
          </header>

          <p>
            感謝您使用 <strong>Lorescape</strong>。我們致力於為您提供最深度的 AI 語音導覽體驗。如果您在使用過程中有任何疑問、建議，或需要回報錯誤，請隨時透過以下方式聯繫我們。
          </p>

          {/* 聯絡我們 callout */}
          <div className="glass-card rounded-2xl p-6 my-8 border-l-4 border-emerald-400/60">
            <div className="flex items-start gap-3">
              <span className="text-2xl leading-none" aria-hidden="true">
                📧
              </span>
              <div className="flex-1 min-w-0">
                <h2>聯絡我們</h2>
                <ul className="space-y-2 list-disc ml-6">
                  <li>
                    <strong>客服信箱</strong>：{" "}
                    <a href="mailto:easylive1989@gmail.com">
                      easylive1989@gmail.com
                    </a>
                  </li>
                  <li>
                    <strong>回覆時間</strong>：我們通常會在 24–48 小時內回覆您的郵件。
                  </li>
                </ul>
              </div>
            </div>
          </div>

          {/* 常見問題 callout */}
          <div className="glass-card rounded-2xl p-6 my-8 border-l-4 border-amber-400/60">
            <div className="flex items-start gap-3">
              <span className="text-2xl leading-none" aria-hidden="true">
                ❓
              </span>
              <div className="flex-1 min-w-0">
                <h2>常見問題</h2>

                <p>
                  <strong>Q：為什麼我聽不到語音導覽的聲音？</strong>
                </p>
                <p>
                  A：請檢查您的手機是否處於靜音模式，並確認您已授權 App 使用音訊播放功能。建議您佩戴耳機以獲得最佳的沉浸式體驗。
                </p>

                <p>
                  <strong>Q：App 需要全程連網嗎？</strong>
                </p>
                <p>
                  A：是的。為了根據您的位置即時生成最準確的 AI 歷史解說內容，您的裝置需要保持網路連線。
                </p>

                <p>
                  <strong>Q：我的位置資訊會被追蹤嗎？</strong>
                </p>
                <p>
                  A：<strong>Lorescape</strong> 僅在您使用「探索周邊」功能時讀取您的當前位置，以提供附近的景點資訊。我們不會在背景持續追蹤您的行蹤，您的隱私對我們至關重要。
                </p>

                <p>
                  <strong>Q：AI 講述的歷史是百分之百準確的嗎？</strong>
                </p>
                <p>
                  A：我們的 AI 扮演「嚴謹的歷史學家」，致力於提供基於史實的資訊。然而，AI 生成內容偶爾可能會有誤差。如果您發現明顯錯誤，歡迎透過 App 內的回報功能告訴我們。
                </p>

                <p>
                  <strong>Q：如何刪除我的帳號與資料？</strong>
                </p>
                <p>
                  A：您隨時可以申請刪除帳號。請在 App 內點選{" "}
                  <strong>[設定]</strong> ＞ <strong>[刪除帳號]</strong>，您的所有個人資料與「知識護照」紀錄將被立即且永久刪除。您也可以透過上述 Email 聯繫我們協助處理。
                </p>
              </div>
            </div>
          </div>
        </article>
      </main>
      <Footer />
    </>
  );
}
