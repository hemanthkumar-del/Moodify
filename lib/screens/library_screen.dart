import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import '../providers/song_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/song_card.dart';
import '../widgets/gradient_cover.dart';
import 'playlist_details_screen.dart';
import '../core/utils/page_transitions.dart';
import '../core/constants/app_colors.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isGridView = false;
  String _sortBy = 'Title'; // Title, Artist, Genre, Date Added
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Sort and filter helper
  List<SongModel> _getSortedAndFilteredSongs(List<SongModel> songs) {
    final filtered = songs.where((s) {
      final q = _query.toLowerCase();
      return s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q) ||
          s.album.toLowerCase().contains(q) ||
          s.genre.toLowerCase().contains(q) ||
          s.mood.toLowerCase().contains(q);
    }).toList();

    switch (_sortBy) {
      case 'Artist':
        filtered.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
        break;
      case 'Genre':
        filtered.sort((a, b) => a.genre.toLowerCase().compareTo(b.genre.toLowerCase()));
        break;
      case 'Date Added':
        filtered.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
      case 'Title':
      default:
        filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SongProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background subtle gradients
          Container(
            width: double.infinity,
            height: double.infinity,
            color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Area
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Your Library",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.add_box_rounded,
                          color: isDark ? Colors.white70 : Colors.black87,
                          size: 28,
                        ),
                        onPressed: () => _showAddSongOptions(context, provider),
                      ),
                    ],
                  ),
                ),

                // Custom Glassmorphic TabBar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    borderRadius: 16,
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: isDark ? Colors.white70 : Colors.black87,
                      labelColor: isDark ? Colors.white : Colors.black87,
                      unselectedLabelColor: isDark ? Colors.white30 : Colors.black38,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: "Songs"),
                        Tab(text: "Playlists"),
                        Tab(text: "Albums"),
                        Tab(text: "Artists"),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Songs Tab Layout
                      _buildSongsTab(context, provider, isDark),
                      
                      // Playlists Tab Layout
                      _buildPlaylistsTab(context, provider, isDark),

                      // Albums Tab Layout
                      _buildAlbumsTab(context, provider, isDark),

                      // Artists Tab Layout
                      _buildArtistsTab(context, provider, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSongOptions(context, provider),
        backgroundColor: isDark ? Colors.white : Colors.black87,
        foregroundColor: isDark ? Colors.black87 : Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Add Song"),
      ),
    );
  }

  Widget _buildSongsTab(BuildContext context, SongProvider provider, bool isDark) {
    final songs = _getSortedAndFilteredSongs(provider.allSongs);

    return Column(
      children: [
        // Search & Filter controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  borderRadius: 14,
                  child: TextField(
                    onChanged: (val) {
                      setState(() {
                        _query = val;
                      });
                    },
                    decoration: InputDecoration(
                      icon: Icon(Icons.search_rounded, color: isDark ? Colors.white30 : Colors.black38),
                      hintText: "Search library songs...",
                      border: InputDecorationTheme().border,
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Icon(Icons.sort_rounded, color: isDark ? Colors.white70 : Colors.black87),
                onSelected: (val) {
                  setState(() {
                    _sortBy = val;
                  });
                },
                itemBuilder: (context) => ['Title', 'Artist', 'Genre', 'Date Added'].map((val) {
                  return PopupMenuItem<String>(
                    value: val,
                    child: Text(val),
                  );
                }).toList(),
              ),
              IconButton(
                icon: Icon(
                  _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
            ],
          ),
        ),

        Expanded(
          child: songs.isEmpty
              ? _buildEmptyState("No songs in your library. Add individual audio tracks or scan storage to begin.")
              : (_isGridView
                  ? GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 80),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: songs.length,
                      itemBuilder: (context, index) {
                        final song = songs[index];
                        return _buildGridSongCard(context, provider, song);
                      },
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 80),
                      itemCount: songs.length,
                      itemBuilder: (context, index) {
                        final song = songs[index];
                        return GestureDetector(
                          onLongPress: () => _showSongOptionsSheet(context, provider, song),
                          child: SongCard(
                            song: song,
                            playlist: songs,
                          ),
                        );
                      },
                    )),
        ),
      ],
    );
  }

  Widget _buildPlaylistsTab(BuildContext context, SongProvider provider, bool isDark) {
    final playlists = provider.playlists;

    return Column(
      children: [
        // Create Playlist Action Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${playlists.length} playlists",
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 14,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showCreatePlaylistDialog(context, provider),
                icon: const Icon(Icons.playlist_add_rounded),
                label: const Text("New Playlist"),
              ),
            ],
          ),
        ),

        Expanded(
          child: playlists.isEmpty
              ? _buildEmptyState("Create custom playlists to group and listen to your songs offline.")
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 80),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return GestureDetector(
                      onLongPress: () => _showPlaylistOptions(context, provider, playlist),
                      child: GlassCard(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        padding: const EdgeInsets.all(12.0),
                        borderRadius: 16,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.my_library_music_rounded,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          title: Text(
                            playlist.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("${playlist.songIds.length} tracks"),
                          trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDark ? Colors.white30 : Colors.black38),
                          onTap: () {
                            Navigator.of(context).push(
                              FadeScalePageRoute(
                                page: PlaylistDetailsScreen(playlist: playlist),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildGridSongCard(BuildContext context, SongProvider provider, SongModel song) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        provider.playSong(song, provider.allSongs);
      },
      onLongPress: () => _showSongOptionsSheet(context, provider, song),
      child: GlassCard(
        padding: const EdgeInsets.all(8.0),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: GradientCover(
                  title: song.title,
                  artist: song.artist,
                  mood: song.mood,
                  size: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_music_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // Floating sheet to choose picker import or storage scan
  void _showAddSongOptions(BuildContext context, SongProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.audio_file_rounded),
                title: const Text("Import individual file"),
                subtitle: const Text("Select .mp3, .wav, .flac, .aac from local files"),
                onTap: () async {
                  Navigator.of(context).pop();
                  final prepared = await provider.pickAndPrepareSong();
                  if (prepared != null) {
                    _showMetadataDialog(context, provider, prepared);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.manage_search_rounded),
                title: const Text("Scan Phone Storage"),
                subtitle: const Text("Auto detect and import music tracks"),
                onTap: () {
                  Navigator.of(context).pop();
                  _showScanLoader(context, provider);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Scanning storage loader indicator
  void _showScanLoader(BuildContext context, SongProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return FutureBuilder(
          future: provider.scanDeviceMusic(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pop();
              });
            }
            return Center(
              child: GlassCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(24),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Scanning storage directories...", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Save/Edit dialog prompt
  void _showMetadataDialog(BuildContext context, SongProvider provider, SongModel song) {
    final titleController = TextEditingController(text: song.title);
    final artistController = TextEditingController(text: song.artist);
    final albumController = TextEditingController(text: song.album);
    final genreController = TextEditingController(text: song.genre);
    String selectedMood = song.mood;

    final moods = ["Happy", "Sad", "Relax", "Workout", "Romantic", "Lonely", "Study", "Sleep"];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Import Metadata Review"),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: "Song Name"),
                    ),
                    TextField(
                      controller: artistController,
                      decoration: const InputDecoration(labelText: "Artist"),
                    ),
                    TextField(
                      controller: albumController,
                      decoration: const InputDecoration(labelText: "Album"),
                    ),
                    TextField(
                      controller: genreController,
                      decoration: const InputDecoration(labelText: "Genre"),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Assign Mood", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: moods.map((m) {
                        final isSelected = selectedMood == m;
                        return ChoiceChip(
                          label: Text(m),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() {
                                selectedMood = m;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    final newSong = song.copyWith(
                      title: titleController.text.trim().isEmpty ? "Unknown Song" : titleController.text.trim(),
                      artist: artistController.text.trim().isEmpty ? "Unknown Artist" : artistController.text.trim(),
                      album: albumController.text.trim().isEmpty ? "Unknown Album" : albumController.text.trim(),
                      genre: genreController.text.trim().isEmpty ? "Unknown Genre" : genreController.text.trim(),
                      mood: selectedMood,
                    );
                    provider.saveImportedSong(newSong);
                    Navigator.of(context).pop();
                  },
                  child: const Text("Import"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Song Long Press sheet
  void _showSongOptionsSheet(BuildContext context, SongProvider provider, SongModel song) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit_note_rounded),
                title: const Text("Edit Metadata / Assign Mood"),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEditSongDialog(context, provider, song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded),
                title: const Text("Add to playlist"),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAddToPlaylistSelection(context, provider, song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                title: const Text("Delete from library", style: TextStyle(color: Colors.redAccent)),
                subtitle: const Text("Original phone file is never deleted"),
                onTap: () {
                  Navigator.of(context).pop();
                  provider.deleteSong(song);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Edit song metadata dialog
  void _showEditSongDialog(BuildContext context, SongProvider provider, SongModel song) {
    final titleController = TextEditingController(text: song.title);
    final artistController = TextEditingController(text: song.artist);
    final albumController = TextEditingController(text: song.album);
    final genreController = TextEditingController(text: song.genre);
    String selectedMood = song.mood;

    final moods = ["Happy", "Sad", "Relax", "Workout", "Romantic", "Lonely", "Study", "Sleep"];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Edit Song Metadata"),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: "Song Name"),
                    ),
                    TextField(
                      controller: artistController,
                      decoration: const InputDecoration(labelText: "Artist"),
                    ),
                    TextField(
                      controller: albumController,
                      decoration: const InputDecoration(labelText: "Album"),
                    ),
                    TextField(
                      controller: genreController,
                      decoration: const InputDecoration(labelText: "Genre"),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Edit Mood Vibe", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: moods.map((m) {
                        final isSelected = selectedMood == m;
                        return ChoiceChip(
                          label: Text(m),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() {
                                selectedMood = m;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    final updated = song.copyWith(
                      title: titleController.text.trim().isEmpty ? "Unknown Song" : titleController.text.trim(),
                      artist: artistController.text.trim().isEmpty ? "Unknown Artist" : artistController.text.trim(),
                      album: albumController.text.trim().isEmpty ? "Unknown Album" : albumController.text.trim(),
                      genre: genreController.text.trim().isEmpty ? "Unknown Genre" : genreController.text.trim(),
                      mood: selectedMood,
                    );
                    provider.updateSongDetails(updated);
                    Navigator.of(context).pop();
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Add song to playlist sheet selection
  void _showAddToPlaylistSelection(BuildContext context, SongProvider provider, SongModel song) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final lists = provider.playlists;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text("Add to Playlist", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (lists.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text("Create a playlist first in the playlists tab.", style: TextStyle(color: Colors.grey)),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: lists.length,
                    itemBuilder: (context, index) {
                      final list = lists[index];
                      return ListTile(
                        leading: const Icon(Icons.playlist_add_check_rounded),
                        title: Text(list.name),
                        onTap: () {
                          provider.addSongToPlaylist(list.id, song.id);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Create playlist dialog
  void _showCreatePlaylistDialog(BuildContext context, SongProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("New Playlist"),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Playlist name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  provider.createPlaylist(name);
                }
                Navigator.of(context).pop();
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  // Playlist options sheet (Rename, Delete)
  void _showPlaylistOptions(BuildContext context, SongProvider provider, PlaylistModel playlist) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text("Rename playlist"),
                onTap: () {
                  Navigator.of(context).pop();
                  _showRenamePlaylistDialog(context, provider, playlist);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                title: const Text("Delete playlist", style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.of(context).pop();
                  provider.deletePlaylist(playlist.id);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showRenamePlaylistDialog(BuildContext context, SongProvider provider, PlaylistModel playlist) {
    final controller = TextEditingController(text: playlist.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Rename Playlist"),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: "New playlist name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  provider.renamePlaylist(playlist.id, name);
                }
                Navigator.of(context).pop();
              },
              child: const Text("Rename"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAlbumsTab(BuildContext context, SongProvider provider, bool isDark) {
    final songs = provider.allSongs;
    final Map<String, List<SongModel>> albumGroups = {};
    for (var song in songs) {
      final albumName = song.album.trim().isNotEmpty ? song.album : "Unknown Album";
      albumGroups.putIfAbsent(albumName, () => []).add(song);
    }

    final albums = albumGroups.keys.where((a) => a.toLowerCase().contains(_query.toLowerCase())).toList();
    albums.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (albums.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.album_rounded, size: 64, color: isDark ? Colors.white24 : Colors.black12),
            const SizedBox(height: 16),
            Text(
              "No albums found",
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final albumName = albums[index];
        final albumSongs = albumGroups[albumName]!;
        final firstSong = albumSongs.first;

        return GestureDetector(
          onTap: () {
            provider.playSong(firstSong, albumSongs);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Playing album: $albumName")),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Hero(
                  tag: 'album_cover_$albumName',
                  child: firstSong.coverPath.isNotEmpty && !firstSong.coverPath.startsWith('assets/')
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(firstSong.coverPath),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return GradientCover(
                                title: albumName,
                                artist: firstSong.artist,
                                mood: firstSong.mood,
                                size: 150,
                              );
                            },
                          ),
                        )
                      : GradientCover(
                          title: albumName,
                          artist: firstSong.artist,
                          mood: firstSong.mood,
                          size: 150,
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                albumName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                "${albumSongs.length} track${albumSongs.length == 1 ? '' : 's'}",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArtistsTab(BuildContext context, SongProvider provider, bool isDark) {
    final songs = provider.allSongs;
    final Map<String, List<SongModel>> artistGroups = {};
    for (var song in songs) {
      final artistName = song.artist.trim().isNotEmpty ? song.artist : "Unknown Artist";
      artistGroups.putIfAbsent(artistName, () => []).add(song);
    }

    final artists = artistGroups.keys.where((a) => a.toLowerCase().contains(_query.toLowerCase())).toList();
    artists.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (artists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_rounded, size: 64, color: isDark ? Colors.white24 : Colors.black12),
            const SizedBox(height: 16),
            Text(
              "No artists found",
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artistName = artists[index];
        final artistSongs = artistGroups[artistName]!;
        final firstSong = artistSongs.first;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
          leading: Hero(
            tag: 'artist_cover_$artistName',
            child: ClipOval(
              child: firstSong.coverPath.isNotEmpty && !firstSong.coverPath.startsWith('assets/')
                  ? Image.file(
                      File(firstSong.coverPath),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return GradientCover(
                          title: artistName,
                          artist: "",
                          mood: firstSong.mood,
                          size: 50,
                          borderRadius: 25,
                        );
                      },
                    )
                  : GradientCover(
                      title: artistName,
                      artist: "",
                      mood: firstSong.mood,
                      size: 50,
                      borderRadius: 25,
                    ),
            ),
          ),
          title: Text(
            artistName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
          subtitle: Text(
            "${artistSongs.length} track${artistSongs.length == 1 ? '' : 's'}",
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white30 : Colors.black38),
          onTap: () {
            provider.playSong(firstSong, artistSongs);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Playing songs by: $artistName")),
            );
          },
        );
      },
    );
  }
}
