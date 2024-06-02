import 'package:flutter/material.dart';

import '../models/failure.dart';
import 'failure_details_page.dart';

class FailureDialogue extends StatelessWidget {
  final Failure failure;
  const FailureDialogue(this.failure, {super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      contentTextStyle: const TextStyle(color: Colors.black),
      titleTextStyle: const TextStyle(
          color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
      title: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_sharp,
            color: Colors.red,
          ),
          SizedBox(
            width: 5,
          ),
        ],
      ),
      content: Text(
        failure.error,
        maxLines: 4,
      ),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Ignore')),
        ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, shape: const StadiumBorder()),
            onPressed: () {
              Navigator.of(context).pop();

              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => FailureDetailsPage(failure: failure)));
            },
            child: const Text('View details'))
      ],
    );
  }

  static show(BuildContext context, {required Failure failure}) {
    if (failure != Failure.none()) {
      showDialog(
          context: context, builder: (context) => FailureDialogue(failure));
    }
  }
}
