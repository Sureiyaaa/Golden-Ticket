import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/rating.dart';
import 'package:golden_ticket_enterprise/widgets/notification_widget.dart';

class RatingDialogWidget extends StatefulWidget {
  final void Function(int rating, String feedback) onSubmit;
  Rating? rating;
  RatingDialogWidget({Key? key, this.rating, required this.onSubmit}) : super(key: key);

  @override
  _RatingDialogWidgetState createState() => _RatingDialogWidgetState();
}

class _RatingDialogWidgetState extends State<RatingDialogWidget> {
  late int _rating;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState(){
    super.initState();
    _rating = widget.rating?.score ?? 0;
    _feedbackController.text = widget.rating?.feedback ?? '';
  }
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: screenWidth * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rate This Chat',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Feedback (optional)',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              minLines: 3,
              decoration: const InputDecoration(
                hintText: 'Share your thoughts...',
                border: OutlineInputBorder(),
              ),

            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if(_rating == 0) return TopNotification.show(context: context, message: '',duration: Duration(seconds: 2), backgroundColor: Colors.redAccent);
                    widget.onSubmit(_rating, _feedbackController.text);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Submit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}
