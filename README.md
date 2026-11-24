## ☕ Buy me a coffee

If you like this project and want to support it, you can buy me a coffee through [PayPal](https://paypal.me/nicovic17) or [Revolut](https://revolut.me/nicoauriemma).

# VanishCam — webcam disappearance effects

The app's on-screen texts and terminal messages are in Brazilian Portuguese. Window texts are drawn with the bundled DejaVu font (`assets/fonts`, see `LICENSE_DEJAVU.txt`) so accents display correctly.

Video is processed on your computer. It is neither recorded nor sent to a server. The virtual camera shows only the video and effects, without overlaid menus, instructions, or text. The preview window adds only a countdown while the empty background is captured (hide it with `--no-countdown`; `AVVIA_OBS.bat` and `avvia_obs.sh` hide it because OBS captures that window).

All packaged Windows EXEs require an active email license and Internet access. The first
launch asks only for your license email, then binds it to this Windows device.
Later launches remember the email but always check Firebase again. No password
or email verification is requested. Only license/device/session data is sent;
the webcam feed stays local. One running instance is allowed across editions.

The Python source launched with `AVVIA_LOCALE.bat` is the local development
version: it starts without Firebase or a license check. Packaged EXEs retain
the online license requirement. Until the server rules include a new effect,
the licensed full EXE reports its session mode as `full`, so a valid license
does not stop renewing while that effect runs.


## Windows executables

[Browse the shop](https://nicoaauriemma.vercel.app/shop) for published downloads. To build from these sources, first copy `license_config.example.json` to the Git-ignored `license_config.json` and fill in the Firebase project ID and client API key. Then run `BUILD_WINDOWS.bat`. It creates four standalone EXEs in `dist/`:

- `VanishCam.exe` offers Normal, Naruto, Particles, Goku and Itachi.
- `Naruto Vanish Effect.exe` starts Naruto directly.
- `Goku Vanish Effect.exe` starts Goku directly.
- `Normal and Particles Vanish.exe` lets you choose Normal Vanish or Particles with the mouse or keys `1` and `2`.

Each EXE includes the models and assets needed for its modes. No separate Python installation is required to run it. Before opening the video, each EXE shows a camera preview: use `+`/`-` or keys `0`–`9` to choose the webcam, then press **Use this webcam** or `Enter`. Passing `--camera N` skips this screen.

## Linux (Ubuntu, Omarchy/Arch)

The Python source runs on Linux without a license check, like `AVVIA_LOCALE.bat`.
The packaged, licensed EXEs remain Windows-only.

1. Install the system packages (once):
   - Ubuntu: `sudo apt install python3 python3-venv ffmpeg`
   - Omarchy/Arch: `sudo pacman -S --needed python ffmpeg`
2. Run `./avvia_locale.sh` from this folder. The first run creates `.venv-local`
   and installs the requirements. Every option works as on Windows, for example
   `./avvia_locale.sh --mode goku --camera 0`.
3. `./avvia_obs.sh` shows only the preview window, and `./avvia_virtual.sh` requires the virtual camera.

**Virtual camera:** Linux uses `v4l2loopback` instead of OBS Virtual Camera.
Run `./setup_virtual_camera.sh` once. It installs the module (`apt` or `pacman`,
with headers for the running kernel), loads it as `/dev/video10` labeled
**VanishCam**, and can enable it at boot. Then select **VanishCam** in your
video-call app. Without the module, the app keeps running with the local preview only.

**Virtual microphone (sound effects in the call):** a webcam carries only video,
so the effect sounds (Naruto's smoke, Goku's teleport) reach the call through a
virtual microphone. Run `./setup_virtual_mic.sh` (PipeWire/PulseAudio, no sudo):
it lists your microphones, you choose one, and it creates **VanishCam Mic** =
that microphone + the effect sounds. Select **VanishCam Mic** as the microphone in
the call app; you still hear the effects on your speakers. The app uses it
automatically when it exists (`--no-virtual-mic` disables it, `--virtual-mic`
requires it). Run the script again to switch microphones, `./setup_virtual_mic.sh
status` to check it and `./setup_virtual_mic.sh remove` to delete it. PipeWire
drops it on reboot: run the script again.

Notes:
- On Linux, `requirements.txt` installs MediaPipe 0.10.35: the 1.x wheels are
  killed (SIGKILL) while creating the vision tasks. On Python 3.14 it installs
  `pygame-ce`, because `pygame` has no 3.14 wheels and a source build has no mixer.
  If the mixer still fails, sounds play through `ffplay` (ffmpeg).
- The preview uses OpenCV's bundled Qt through XWayland. The app sets
  `QT_QPA_PLATFORM=xcb` itself, so this works on Wayland sessions (Hyprland, GNOME, KDE).
- If the webcam does not open, check that your user can read `/dev/video*`
  (`video` group). Webcams also expose metadata nodes: try `--camera 0` first.

## Getting started

1. Double-click `AVVIA_LOCALE.bat`.
2. In the start menu, choose **Normal Vanish**, **Naruto Vanish**, **Particles**, **Goku**, or **Itachi Uchiha Disappear** with the mouse or keys `1` to `5`.
3. Choose your webcam in the preview, then confirm with the button or `Enter`.
   Goku then asks how long to hold the gesture to disappear or reappear: press
   `Enter` for the default 1 second, or type a positive decimal such as `0.5`
   or `0.1`. A decimal comma (`0,5`) also works. Cancel stops the launch.
4. Step out of the camera frame for 4 seconds while the empty background is captured. The preview shows a countdown ring; press `SPACE` at any time to capture the background again.

**Normal Vanish:** Raise your index and middle fingers in a V sign. The dissolve starts as soon as the gesture is recognized and lasts about 3.6 seconds. To reappear, lower your hand and make the V sign again (or press `R`): the dissolve plays in reverse.

**Particles:** Make the same V sign as in Normal Vanish. Your silhouette breaks into small colored fragments that drift sideways as if carried by the wind. The effect lasts about 2.1 seconds. It captures your silhouette once when the effect starts to keep the video smooth. To reappear, lower your hand and make the V sign again (or press `R`): the particles fly back and rebuild you.

**Goku:** After choosing the webcam, set the gesture hold time (default 1 second; decimals such as `0.5` and `0.1` are accepted). Hold your index and middle fingers straight and together against your forehead for the selected duration. Animated vertical comic-style lines run across your silhouette just before you teleport away and linger briefly afterward. To reappear, lower your hand, then repeat the gesture for the same selected duration. The return uses the reverse effect. If you break the pose, the countdown starts over. `assets/teleport.MP3` plays on both disappearance and reappearance. The terminal shows the countdown for each gesture. The `V` and `R` keys are disabled in this mode: the gesture is the only way to disappear and reappear. No text is overlaid on the video.

Português: no modo Goku, depois de escolher a webcam aparece uma janela para
definir por quanto tempo segurar o gesto para sumir ou reaparecer. Aperte
`Enter` para 1 segundo, ou digite por exemplo `0.5`, `0.1` ou `0,5`. O valor
deve ser maior que zero. `Continuar` confirma; `Cancelar` ou `ESC` encerram a
abertura. Sumir e reaparecer usam o mesmo tempo escolhido.

**Naruto Vanish:** Bring your palms together in front of the webcam, with your fingers side by side rather than interlaced. Keep both hands visible. As soon as the gesture is recognized, you vanish in a cloud of smoke and a wooden log appears and falls. As soon as it lands it disappears in another puff of smoke (set `LOG_HOLD_SECONDS` in `naruto_effect.py` to keep it on the floor longer). To reappear, release your hands and join them again, or press `R`: you come back inside a cloud of smoke. No microphone is needed. Naruto mode uses `hand_landmarker.task` to track both hands. `assets/vanish.MP3` plays through your computer speakers when the disappearance starts, including when triggered with `V`. You can trigger it again after pressing `R`.

**Itachi Uchiha Disappear:** Touch both hands in front of the center of your chest, with both hands visible. Parts of your captured silhouette turn into individually flapping, cel-shaded crows that fly in curved paths. Larger crows cross the foreground, with brief ink edges, flight streaks and drifting feathers. A translucent blood-red ink texture covers the captured room during the transformation and remains while you are invisible. The supplied Sharingan eyes appear briefly at the top of the frame, then fade away. Release your hands, then touch them at your chest again to reappear as the crows converge and reconstruct your silhouette; the red background fades back to the real room. The transition lasts about 4 seconds in each direction. `V` previews the disappearance and `R` starts the animated return when you are back in frame. This mode uses the bundled hand landmarker and does not add audio. Adjust `EFFECT_SECONDS` and `BODY_RELEASE_SECONDS` in `itachi_effect.py` to tune its pacing.

To start a mode without the menu:

```powershell
local_app\AVVIA_LOCALE.bat --mode naruto
local_app\AVVIA_LOCALE.bat --mode normal
local_app\AVVIA_LOCALE.bat --mode particles
local_app\AVVIA_LOCALE.bat --mode goku
local_app\AVVIA_LOCALE.bat --mode itachi
```

## Virtual camera and OBS

If [OBS Studio](https://obsproject.com/) is installed, the app automatically tries to open **OBS Virtual Camera**. The terminal shows the device name. Use `AVVIA_VIRTUAL.bat` to require a virtual camera. Select **OBS Virtual Camera** in the app that will receive the video. OBS's virtual camera must be stopped while this app is producing its output.

To use the effect in an OBS scene, run `AVVIA_OBS.bat`, add a **Window Capture** source, select **Webcam - Preview**, and then start the virtual camera from OBS. Alternatively, use [Unity Capture](https://github.com/schellingb/UnityCapture) as a separate virtual video source:

```powershell
local_app\AVVIA_VIRTUAL.bat --virtual-backend unitycapture
```

OBS has only one virtual camera. Do not use it as both an OBS input and output at the same time. See the [pyvirtualcam documentation](https://github.com/letmaik/pyvirtualcam#supported-virtual-cameras).

## Controls

- `SPACE`: capture a new background.
- `R`: make the person reappear.
- `V`: manually start the selected mode's effect.
- `F`: toggle fullscreen.
- `M`: return to the effect menu, keeping the same webcam and the captured background: the next effect starts right away, without a new 4-second capture (`SPACE` captures a new one).
- `Q` or `ESC`: quit and release the cameras.

Shortcuts also work with Caps Lock or Shift.

The `V` and `R` keys are disabled in Goku mode.

You can change the camera, resolution, and maximum virtual-output FPS:

```powershell
local_app\AVVIA_LOCALE.bat --camera 1 --width 1280 --height 720 --fps 30
```

To troubleshoot gesture recognition without adding text to the video, pass `--gesture-debug`. Diagnostic information appears only in the terminal.

## Visual assets

The [wooden log](assets/substitution_log.png) is an original illustration generated with ImageGen using the supplied image as a visual reference. Smoke is drawn in real time by `naruto_effect.py` so it follows the person's position and scales with the video. We also considered a [CC0 smoke sprite sheet](https://opengameart.org/content/smoke-sprite-sheet), but the procedural animation adapts better to dynamic positioning without an additional asset.

Goku mode uses the [MediaPipe BlazeFace short-range model](https://github.com/google-ai-edge/mediapipe/blob/master/mediapipe/tasks/web/vision/README.md) to estimate the forehead position and `hand_landmarker.task` to track the fingers. The teleport's visual trace is drawn in code, without anime frames.
