import 'package:flutter/material.dart';
import '../models/team_model.dart';

class TeamListWidget extends StatelessWidget {
  final List<TeamModel> teams;

  const TeamListWidget({Key? key, required this.teams}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];
        return Card(
          color: Colors.blueGrey[700],
          child: ListTile(
            title: Text(
                team.names.join(', '),
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              team.teams.join(', '),
              style: TextStyle(color: Colors.white70),
            ),
          ),
        );
      },
    );
  }
}
