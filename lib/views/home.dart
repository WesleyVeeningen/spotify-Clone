import 'package:flutter/foundation.dart' show Image;
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
  late List<Music> otherSongs = [];

  @override
  void initState() {
    super.initState();
    initMusic();
  }

  Future<Music> fetchTrackDetails(String trackId) async {
    final spotify = SpotifyApi(SpotifyApiCredentials(
      CustomStrings.clientId,
      CustomStrings.clientSecret,
    ));

    final track = await spotify.tracks.get(trackId);
    final tempSongName = track.name ?? '';
    final tempArtistName = track.artists?.first.name ?? '';
    final tempSongImage = track.album?.images?.first.url ?? '';
    final tempArtistImage = track.artists?.first.images?.first.url ?? '';

    return Music(
      trackId: track.id ?? '',
      songName: tempSongName,
      artistName: tempArtistName,
      songImage: tempSongImage,
      artistImage: tempArtistImage,
    );
  }

  Future<void> initMusic() async {
    // List of track IDs to search for
    List<String> trackIds = []; //<track_ids>

    List<String> otherTrackIds = []; //<other_track_ids>

    List<Music> fetchedSongs = [];
    List<Music> otherFetchedSongs = [];

    await Future.wait([
      for (String trackId in trackIds)
        fetchTrackDetails(trackId).then((music) => fetchedSongs.add(music)),
      for (String otherTrackId in otherTrackIds)
        fetchTrackDetails(otherTrackId)
            .then((music) => otherFetchedSongs.add(music)),
    ]);

    setState(() {
      songs = fetchedSongs;
      filteredSongs = songs; // Initialize filteredSongs with all songs
      otherSongs = otherFetchedSongs;
    });
  }

  void addSong(String trackId) async {
    final music = await fetchTrackDetails(trackId);

    setState(() {
      songs.add(music);
      filteredSongs = songs; // Initialize filteredSongs with all songs
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
      body: SingleChildScrollView(
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
              itemCount: (filteredSongs.length / 2)
                  .ceil(), // Divide by 2 and ceil to get the number of rows needed
              itemBuilder: (context, index) {
                final firstSongIndex = index * 2;
                final secondSongIndex = firstSongIndex + 1;

                // Check if the second song index exceeds the number of filtered songs
                final hasSecondSong = secondSongIndex < filteredSongs.length;

                return Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: Text(
                          filteredSongs[firstSongIndex].songName!,
                          style: const TextStyle(
                            color: Color.fromRGBO(255, 255, 255, 1),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(
                              filteredSongs[firstSongIndex].songImage!),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MusicPlayer(
                                  trackId:
                                      filteredSongs[firstSongIndex].trackId),
                            ),
                          );
                        },
                      ),
                    ),
                    if (hasSecondSong)
                      Expanded(
                        child: ListTile(
                          title: Text(
                            filteredSongs[secondSongIndex].songName!,
                            style: const TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 1),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(
                                filteredSongs[secondSongIndex].songImage!),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MusicPlayer(
                                    trackId:
                                        filteredSongs[secondSongIndex].trackId),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.all(0),
              child: Text(
                'Other Songs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 0), // Adjust the left padding as needed
              child: SizedBox(
                height: 200, // Adjust the height as needed
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: otherSongs.length,
                  itemBuilder: (context, index) {
                    final song = otherSongs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: 150, // Adjust the width as needed
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(song.songImage!),
                              radius: 40,
                            ),
                            Text(
                              song.songName!,
                              style: const TextStyle(color: Colors.white),
                              maxLines: 2, // Adjust the max lines as needed
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              song.artistName!,
                              style: const TextStyle(color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
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
        : songs
            .where((song) =>
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

  AddSongDialog({Key? key});

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
