// import 'package:flutter/material.dart';
// import 'package:tournament_bracket/tournament_bracket.dart';

// void main() {
//   runApp(const testApp());
// }

// class testApp extends StatelessWidget {
//   const testApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         // This is the theme of your application.
//         //
//         // Try running your application with "flutter run". You'll see the
//         // application has a blue toolbar. Then, without quitting the app, try
//         // changing the primarySwatch below to Colors.green and then invoke
//         // "hot reload" (press "r" in the console where you ran "flutter run",
//         // or simply save your changes to "hot reload" in a Flutter IDE).
//         // Notice that the counter didn't reset back to zero; the application
//         // is not restarted.
//         primarySwatch: Colors.blue,
//       ),
//       home: MyhomePage(),
//     );
//   }
// }

// class MyhomePage extends StatelessWidget {
//   MyhomePage({
//     super.key,
//   });

//   final all = [
//     List.generate(
//         20, (index) => Team(name: 'team1 ${index + 1}', age: index + 1)),
//     List.generate(
//         7, (index) => Team(name: 'team1 ${(index * 2) + 1}', age: index + 1)),
//     List.generate(
//         2, (index) => Team(name: 'team3 ${index + 1}', age: index + 1))
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("title"),
//       ),
//       body: TBracket<Team>(
//         space: 200 / 4,
//         separation: 150,
//         stageWidth: 200,
//         onSameTeam: (team1, team2) {
//           if (team1 != null && team2 != null) {
//             return team1.name == team2.name;
//           }
//           return false;
//         },
//         hadderBuilder: (context, index, count) => Container(
//             alignment: Alignment.center,
//             width: 220,
//             padding: const EdgeInsets.all(15),
//             decoration: BoxDecoration(
//                 borderRadius: const BorderRadius.all(Radius.circular(10)),
//                 border: Border.all(width: 1)),
//             child: Text("Level ${count - 1 == index ? 'winner' : index + 1}")),
//         lineIcon: LineIcon(
//             icon: Icons.add, backgroundColor: Colors.yellow, iconsSize: 20),
//         connectorColor: Color.fromARGB(144, 244, 67, 54),
//         winnerConnectorColor: Colors.green,
//         teamContainerDecoration:
//             BracketBoxDecroction(borderRadious: 15, color: Colors.black),
//         stageIndicatorBoxDecroction: BracketStageIndicatorBoxDecroction(
//             borderRadious: const Radius.circular(15),
//             primaryColor: Color.fromARGB(15, 247, 123, 123),
//             secondaryColor: Color.fromARGB(15, 194, 236, 147)),
//         containt: all,
//         teamNameBuilder: (Team t) {
//           return BracketText(
//             text: t.name,
//             textStyle: const TextStyle(
//                 color: Colors.black, fontWeight: FontWeight.bold),
//           );
//         },
//         onContainerTapDown: (Team? model, TapDownDetails tapDownDetails) {
//           if (model == null) {
//             print(null);
//           } else {
//             print(model.name);
//           }
//         },
//         onLineIconPress: ((team1, team2, tapDownDetails) {
//           if (team1 != null && team2 != null) {
//             print("${team1.name} and ${team2.name}");
//           } else {
//             print(null);
//           }
//         }),
//         context: context,
//       ),
//     );
//   }
// }

// class Team {
//   Team({
//     required this.name,
//     required this.age,
//   });

//   final int age;
//   final String name;
// }
