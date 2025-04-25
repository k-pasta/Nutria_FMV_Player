import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nutria_fmv_player/custom_widgets/windows_app_layout.dart';
import 'package:nutria_fmv_player/models/option.dart';
import 'package:nutria_fmv_player/models/video_node.dart';
import 'package:nutria_fmv_player/providers/nodes_provider.dart';
import 'package:nutria_fmv_player/providers/theme_provider.dart';
import 'package:nutria_fmv_player/providers/ui_state_provider.dart';
import 'package:nutria_fmv_player/providers/video_manager_provider.dart';
import 'package:nutria_fmv_player/providers/video_player_stack_provider.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Necessary initialization for package:media_kit.
  MediaKit.ensureInitialized();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => ThemeProvider()),
      // ChangeNotifierProvider(create: (context) => VideoManagerProvider()),
      ChangeNotifierProvider(create: (context) => VideoPlayerStackProvider()),
      ChangeNotifierProvider(create: (context) => NodesProvider()),
      ChangeNotifierProvider(create: (context) => UiStateProvider()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nutria FMV Player',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeProvider themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      // backgroundColor: themeProvider.currentAppTheme.backgroundColor,
      backgroundColor: Colors.black,
      body: WindowsAppLayout(),
    );
  }
}
