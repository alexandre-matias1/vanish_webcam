"""Preload an MP3 and play it without blocking video frames."""

from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path


SOUND_PATH = Path(__file__).resolve().parent / "assets" / "vanish.MP3"
TELEPORT_SOUND_PATH = Path(__file__).resolve().parent / "assets" / "teleport.MP3"


class VanishSound:
    def __init__(self, path: Path = SOUND_PATH):
        if not path.is_file():
            raise RuntimeError(f"Áudio de desaparecimento não encontrado: {path}")
        self.path = path

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

    def play(self) -> None:
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
