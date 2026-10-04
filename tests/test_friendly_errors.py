from app.services.yt_dlp_service import YtDlpService


def test_translate_error_ffmpeg_missing():
    err = Exception("ffmpeg is not installed, unable to extract audio")
    msg, details = YtDlpService.translate_error(err)
    assert "FFmpeg error" in msg or "FFmpeg is missing" in msg or "PATH" in msg


def test_translate_error_private_or_sign_in():
    err = Exception("Sign in to confirm you’re not a bot or this video is private")
    msg, details = YtDlpService.translate_error(err)
    assert "private" in msg.lower() or "cookies.txt" in msg


def test_translate_error_network_connection():
    err = Exception("urllib.error.URLError: <urlopen error [Errno 11001] getaddrinfo failed>")
    msg, details = YtDlpService.translate_error(err)
    assert "Network" in msg or "connection" in msg.lower() or "internet" in msg.lower()


def test_translate_error_geo_restriction():
    err = Exception("The uploader has not made this video available in your country")
    msg, details = YtDlpService.translate_error(err)
    assert "region" in msg.lower() or "country" in msg.lower()
