from app.services.playlist_service import PlaylistService


def test_playlist_range_selection():
    # 50 total items, range 10 to 20
    indices = PlaylistService.calculate_range_selection(total=50, start=10, end=20)
    assert len(indices) == 11
    assert indices[0] == 9  # 0-indexed position 10
    assert indices[-1] == 19  # 0-indexed position 20


def test_playlist_range_clamped_boundaries():
    # start < 1, end > total
    indices = PlaylistService.calculate_range_selection(total=10, start=-5, end=25)
    assert len(indices) == 10
    assert indices == list(range(10))

    # start > end
    indices2 = PlaylistService.calculate_range_selection(total=10, start=8, end=4)
    # Start should be clamped/maintained
    assert len(indices2) >= 1


def test_playlist_first_n_selection():
    indices = PlaylistService.calculate_first_n_selection(total=25, n=5)
    assert indices == [0, 1, 2, 3, 4]

    # N larger than total
    indices_all = PlaylistService.calculate_first_n_selection(total=5, n=50)
    assert indices_all == [0, 1, 2, 3, 4]

    # Empty total
    assert PlaylistService.calculate_first_n_selection(total=0, n=5) == []
