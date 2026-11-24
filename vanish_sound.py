"""Preload an MP3 and play it without blocking video frames."""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path


SOUND_PATH = Path(__file__).resolve().parent / "assets" / "vanish.MP3"
TELEPORT_SOUND_PATH = Path(__file__).resolve().parent / "assets" / "teleport.MP3"
# Created by setup_virtual_mic.sh: what plays here reaches "VanishCam Mic".
VIRTUAL_MIC_SINK = "vanishcam_fx"


def find_virtual_mic_player() -> list[str] | None:
    """Linux: command that plays a file into the VanishCam Mic, or None if absent."""
    if not sys.platform.startswith("linux") or shutil.which("pactl") is None:
        return None
    try:
        sinks = subprocess.run(["pactl", "list", "short", "sinks"], capture_output=True,
                               text=True, timeout=3).stdout
    except (OSError, subprocess.SubprocessError):
        return None
    if VIRTUAL_MIC_SINK not in {line.split("\t")[1] for line in sinks.splitlines()
                                if line.count("\t") >= 1}:
        return None
    if player := shutil.which("pw-play"):
        return [player, "--target", VIRTUAL_MIC_SINK]
    if player := shutil.which("paplay"):
        return [player, "-d", VIRTUAL_MIC_SINK]
    return None


class VanishSound:
    def __init__(self, path: Path = SOUND_PATH, virtual_mic: list[str] | None = None):
        if not path.is_file():
            raise RuntimeError(f"Áudio de desaparecimento não encontrado: {path}")
        self.path = path
        # Optional second copy of each sound for the call (see find_virtual_mic_player).
        self.virtual_mic = virtual_mic
        self.mic_process = None

        os.environ.setdefault("PYGAME_HIDE_SUPPORT_PROMPT", "1")
        self.process = None
        self.ffplay = None
        self.owns_mixer = False
        try:
            from pygame import mixer
            self.mixer = mixer
            self.owns_mixer = mixer.get_init() is None
            if self.owns_mixer:
                mixer.init(frequency=44100, size=-16, channels=2, buffer=256)
            self.sound = mixer.Sound(str(path))  # Decode once, before opening the webcam.
        except Exception as error:
            # ImportError, or a pygame built without SDL_mixer (NotImplementedError),
            # or no audio device: fall back to ffplay (ffmpeg) when available.
            if self.owns_mixer:
                self.mixer.quit()
                self.owns_mixer = False
            self.ffplay = shutil.which("ffplay")
            if self.ffplay is None:
                raise RuntimeError(
                    f"Não foi possível abrir o áudio de desaparecimento: {error}. "
                    f"Para tocar {path.name}, instale o pygame (com mixer) ou o ffplay (ffmpeg)."
                ) from error

    def _play_on_virtual_mic(self) -> None:
        if self.virtual_mic is None:
            return
        self._stop_virtual_mic()
        try:
            self.mic_process = subprocess.Popen(
                [*self.virtual_mic, str(self.path)],
                stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            )
        except OSError:
            self.mic_process = None  # The call just misses the effect; speakers still play.

    def _stop_virtual_mic(self) -> None:
        if self.mic_process is not None and self.mic_process.poll() is None:
            self.mic_process.terminate()

    def play(self) -> None:
        self._play_on_virtual_mic()
        if self.ffplay is not None:
            if self.process is not None and self.process.poll() is None:
                self.process.terminate()
            try:
                self.process = subprocess.Popen(
                    [self.ffplay, "-nodisp", "-autoexit", "-loglevel", "quiet",
                     "-i", str(self.path)],
                    stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
                )
            except OSError as error:
                raise RuntimeError(f"Não foi possível tocar o áudio de desaparecimento: {error}") from error
            return
        self.sound.stop()
        if self.sound.play() is None:
            raise RuntimeError("Não foi possível tocar o áudio de desaparecimento: nenhum canal livre.")

    def stop(self) -> None:
        self._stop_virtual_mic()
        if self.ffplay is not None:
            if self.process is not None and self.process.poll() is None:
                self.process.terminate()
            return
        self.sound.stop()

    def close(self) -> None:
        self.stop()
        if self.ffplay is not None:
            return
        if self.owns_mixer:
            self.mixer.quit()
            self.owns_mixer = False
