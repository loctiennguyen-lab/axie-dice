# UI-07 Màn đăng nhập: prompt cho Claude Design

**Cho Liam:**
- Dán phần dưới dòng `---` vào cùng project Claude Design đã làm UI-05 và UI-06, đính kèm `send/AxieDice-UI07-login-inputs.zip`.
- Gửi chung với UI-06 hay sau đều được. Đây là đợt nhỏ, riêng.

Quyết định của Liam (1/11):
- màn riêng toàn màn hình, thay popup "Save your progress";
- hiện mỗi lần MỞ GAME khi chưa đăng nhập, **trước Tutorial**;
- phiên hết hạn cũng phải qua màn này;
- vẫn cho chơi guest;
- Claude Design vẽ.

Đã sửa theo review ux-designer (thứ tự màn, web không có popup, offline, phiên hết hạn, luật không blur).

---

One more small screen, separate from UI-06: **a full-screen sign-in screen**. Same style and rules as UI-05: Style A "Toy Wood", `round-2/tokens.json`, and the "Rules carried over" list in the UI-06 brief.

## How the game opens (screenshots in the zip)
1. **Web page shell** (`00-web-loader-tap-to-start`). It is HTML outside the game: logo, the 5 class Axies, dice, "Tap to start", then a loading bar. Leave it as it is. The new screen should feel like the next step after it.
2. The game asks the server who the player is. **If the server can't be reached**, nothing can open today, guest included. That is the offline gate `a13`.
3. **New: the sign-in screen** shows here whenever the player isn't signed in, or their session expired.
   - "Every time" means every time the game **starts**, not every time the player comes back to the Land.
   - A signed-in player never sees it.
4. Then a new player goes to the **Tutorial**. Everyone else goes to the **Land** (the 3D home island).
5. After a sign-in, the Land may open **Choose a save** (`a15`, when this device and the account both have progress) or **Move guest progress** (`a16`). These stay as they are, over the Land, not on this screen.

Today a popup "Save your progress" (`a14`) does this job over the Land, only on the first launch. The new screen replaces it.

## Sign-in rules (from the code, don't change them)
- **Google is the only sign-in method.** Don't draw email/password or any other provider.
- A Sky Mavis work Google account works too. Say that as **text only**, not as a second button.
- **Web:** the page leaves for Google and comes back, and the game reloads. There is no popup to wait for. Draw only a short "Opening Google…" state on the button.
- **Desktop:** the system browser opens and the game waits. Keep the existing desktop overlay (`a09`–`a12`) as a modal over this screen, with one primary in it ("Open browser again"). Restyle it only if needed.
- **Guest** plays the tutorial and normal runs only: no ranked, no Missions, nothing saved to the cloud. Say it plainly, not as a scare.
- Terms and Privacy open in the browser (`/terms`, `/privacy`). On desktop that is the system browser.

## Content
- the Axie Dice logo, and one line about the game;
- **Continue with Google**: the one primary button, with the Space keycap;
- **Play as guest**: quiet, below it;
- the 3 short benefits of signing in, as in `a14`: Vault, Shards & Pass, Continue on another device;
- the Sky Mavis tag;
- a small footer: Terms · Privacy and the version number.

**Background:** a calm Homeland scene from `axie-reference/` in the UI-06 zip.
- It must be a **pre-blurred or low-contrast baked image**, flat. Our UI has no live blur, no gradient overlay and no shader.
- The panel has one solid background.
- Never draw an Axie yourself. If you want Axies here, leave a frame labelled "Axie 3D" and we place the live 3D models.

## States (each at 1920×1080 and 1280×720; each names its one primary)
1. **Default** · primary: Google.
2. **Opening Google…** (web, short) · the Google button shows that it is working.
3. **Desktop waiting**: the `a09`/`a10` overlay on top · primary inside it: Open browser again.
4. **Sign-in failed / cancelled** · primary: Try again.
   - The reason comes from the game. It can be cancelled, timed out, work account blocked or rate limited.
   - Leave room for 2–3 lines, because the "company account blocked" text is long.
5. **Offline** (can't reach the server) · primary: Try again.
   - This replaces the `a13` gate, so it becomes a state of this screen.
   - Google AND Play as guest are both **disabled**, each saying why, because guest needs the server too.
6. **Session expired** (was signed in) · primary: Google.
   - Text: "Your session expired. Sign in again. Your progress on this device is safe."
   - The quiet button becomes "Keep playing without cloud save".
7. **Returning guest** · primary: Google.
   - Same as default, plus a line under the guest button: "N runs on this device". N is a real count we pass in.
   - The guest label stays "Play as guest".

## Behaviour
- Focus starts on Continue with Google. Tab moves Google → Guest → footer links.
- **Esc: no-op.** There is nowhere to go back to. Write that in the spec of the screen.
- Text sizes come only from the tokens (16 / 18 / 24 / 32). Footer and side lines must be at least 14 px real at 1280.
- Motion: a short, calm intro (the logo settles, the panel rises). Include a reduced-motion version and a timing table as in UI-05.

## Send back
- `ui07-login.html`: frames `07-login--<state>` at both sizes, with `data-name` + `aria-label` on every node;
- tokens marked "UI-07";
- `assets/` (with the baked background);
- `motion-ui07.md`;
- a short README: what replaces what, new components, flags, copy.
