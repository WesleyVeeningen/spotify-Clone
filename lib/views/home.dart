import 'package:flutter/material.dart';
import 'package:mobile_music_player_lyrics/constants/strings.dart';
import 'package:mobile_music_player_lyrics/models/music.dart';
import 'package:mobile_music_player_lyrics/views/music_player.dart';
import 'package:spotify/spotify.dart';


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<Music> songs = [];
  late List<Music> filteredSongs = [];

  @override
  void initState() {
    super.initState();
    initMusic();
  }

  Future<void> initMusic() async {
    final credentials = SpotifyApiCredentials(
      CustomStrings.clientId,
      CustomStrings.clientSecret,
    );
    final spotify = SpotifyApi(credentials);

    // List of track IDs to search for
    List<String> trackIds = [
      '7LoWAhcGbxSkT6trTqXQR6',
      '7MXVkk9YMctZqd1Srtv4MB',
      '1wVuPmvt6AWvTL5W2GJnzZ',
      '4iJyoBOLtHqaGxP12qzhQI', // Driver's License by Olivia Rodrigo
      '2VxeLyX666F8uXCJ0dZF8B', // Shivers by Ed Sheeran
      '0nbXyq5TXYPCO7pr3N8S4I', // Levitating by Dua Lipa
      '1EzrEOXmMH3G43AXT1y7pA', // Bad Habits by Ed Sheeran
      // Add more track IDs from Spotify here
    ];

    List<Music> fetchedSongs = [];
    for (String trackId in trackIds) {
      final track = await spotify.tracks.get(trackId);

      final tempSongName = track.name ?? '';
      final tempArtistName = track.artists?.first.name ?? '';
      final tempSongImage = track.album?.images?.first.url ?? '';
      final tempArtistImage = track.artists?.first.images?.first.url ?? '';

      final music = Music(
        trackId: track.id ?? '',
        songName: tempSongName,
        artistName: tempArtistName,
        songImage: tempSongImage,
        artistImage: tempArtistImage,
      );
      fetchedSongs.add(music);
    }

    setState(() {
      songs = fetchedSongs;
      filteredSongs = songs; // Initialize filteredSongs with all songs
    });
  }

  void filterSongs(String query) {
    setState(() {
      filteredSongs = songs
          .where((song) =>
              song.songName!.toLowerCase().contains(query.toLowerCase()))
          .toList();
          if (query.isEmpty) {
            filteredSongs = songs;
          }
    });
  }

  void addSong(String trackId) async {
    final credentials = SpotifyApiCredentials(
      CustomStrings.clientId,
      CustomStrings.clientSecret,
    );
    final spotify = SpotifyApi(credentials);

  final artist = await spotify.artists.get('0OdUWJ0sBjDrqHygGUXeCF');
    final track = await spotify.tracks.get(trackId);

    final tempSongName = track.name ?? '';
    final tempArtistName = track.artists?.first.name ?? '';
    final tempSongImage = track.album?.images?.first.url ?? '';
    final tempArtistImage = track.artists?.first.images?.first.url ?? '';

    final music = Music(
      trackId: track.id ?? '',
      songName: tempSongName,
      artistName: tempArtistName,
      songImage: tempSongImage,
      artistImage: tempArtistImage,
    );

    setState(() {
      songs.add(music);
      filteredSongs = songs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: const Text('Home Page', style: TextStyle(color: Colors.white)),
      ),
      body:  SingleChildScrollView(
        
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'All Songs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: filteredSongs.length,
  itemBuilder: (context, index) {
    final song = filteredSongs[index];
    return ListTile(
      title: Text(
        song.songName!,
        style: const TextStyle(color: Color.fromRGBO(255, 255, 255, 1)),
        overflow: TextOverflow.ellipsis, // Apply text overflow handling
      ),
      leading: CircleAvatar(
        backgroundImage: NetworkImage(song.songImage!),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MusicPlayer(trackId: song.trackId),
          ),
        );
      },
    );
  },
),

          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          String? newTrackId = await showDialog(
            context: context,
            builder: (context) => AddSongDialog(),
          );

if (newTrackId != null && newTrackId.isNotEmpty) {
    newTrackId = newTrackId.trim();
    
    // Check if the input is a Spotify link
    if (newTrackId.contains('spotify.com')) {
        // Extract the track ID from the Spotify link
        final trackId = newTrackId.split('/').last.split('?').first;
        
        // Add the track using the extracted track ID
        addSong(trackId);
    } else {
        // Handle the case when the input is not a Spotify link
        // For example, you might display an error message to the user
    }
}

        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class SongSearch extends SearchDelegate<Music> {
  final List<Music> songs;
  final Function(String) onSearch;

  SongSearch(this.songs, this.onSearch);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, Music(trackId: ''));
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final filteredSongs = query.isEmpty
        ? songs
        : songs.where((song) =>
                song.songName!.toLowerCase().contains(query.toLowerCase()))
            .toList();

    return ListView.builder(
      itemCount: filteredSongs.length,
      itemBuilder: (context, index) {
        final song = filteredSongs[index];
        return ListTile(
          title: Text(song.songName!),
          leading: CircleAvatar(
            backgroundImage: NetworkImage(song.songImage!),
          ),
          onTap: () {
            onSearch(query); // Update the parent widget's filteredSongs list
            close(context, song);
          },
        );
      },
    );
  }
}

class AddSongDialog extends StatelessWidget {
  final TextEditingController _textEditingController = TextEditingController();

  AddSongDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Song'),
      content: TextField(
        controller: _textEditingController,
        decoration: const InputDecoration(hintText: 'Enter Spotify Url'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, null); // Return null to indicate cancel
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            String enteredTrackId = _textEditingController.text.trim();
            if (enteredTrackId.isNotEmpty) {
              Navigator.pop(context, enteredTrackId); // Return entered track ID
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a track ID')),
              );
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: HomePage(),
  ));
}
