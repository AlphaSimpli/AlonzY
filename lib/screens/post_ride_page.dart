import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../widgets/map_picker_widget.dart';

class PostRidePage extends StatefulWidget {
  const PostRidePage({super.key});

  @override
  State<PostRidePage> createState() => _PostRidePageState();
}

class _PostRidePageState extends State<PostRidePage> {
  final dbService = DatabaseService();
  
  final startLocationController = TextEditingController();
  final endLocationController = TextEditingController();
  final startLatController = TextEditingController();
  final startLngController = TextEditingController();
  final endLatController = TextEditingController();
  final endLngController = TextEditingController();
  final availableSeatsController = TextEditingController(text: '3');
  final pricePerSeatController = TextEditingController();
  final vehiclePlateController = TextEditingController();
  final notesController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String selectedVehicleType = 'sedan';
  bool loading = false;

  final vehicleTypes = ['sedan', 'suv', 'van'];

  @override
  void dispose() {
    startLocationController.dispose();
    endLocationController.dispose();
    startLatController.dispose();
    startLngController.dispose();
    endLatController.dispose();
    endLngController.dispose();
    availableSeatsController.dispose();
    pricePerSeatController.dispose();
    vehiclePlateController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != selectedTime) {
      setState(() => selectedTime = picked);
    }
  }

  Future<void> _submitRide() async {
    // Validate inputs
    if (startLocationController.text.isEmpty ||
        endLocationController.text.isEmpty ||
        startLatController.text.isEmpty ||
        startLngController.text.isEmpty ||
        endLatController.text.isEmpty ||
        endLngController.text.isEmpty ||
        pricePerSeatController.text.isEmpty ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Please fill all required fields")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // Combine date and time
      final departureDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      // Create ride
      final rideId = await dbService.createRide(
        startLocation: startLocationController.text.trim(),
        startLat: double.parse(startLatController.text),
        startLng: double.parse(startLngController.text),
        endLocation: endLocationController.text.trim(),
        endLat: double.parse(endLatController.text),
        endLng: double.parse(endLngController.text),
        departureTime: departureDateTime,
        availableSeats: int.parse(availableSeatsController.text),
        pricePerSeat: double.parse(pricePerSeatController.text),
        vehicleType: selectedVehicleType,
        vehiclePlate: vehiclePlateController.text.isEmpty
            ? null
            : vehiclePlateController.text.trim(),
        notes: notesController.text.isEmpty ? null : notesController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Ride posted successfully! ID: $rideId"),
          duration: const Duration(seconds: 2),
        ),
      );

      // Clear form and go back
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error posting ride: $e")),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post a Ride")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Start Location
            Text("Start Location", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: startLocationController,
                    decoration: const InputDecoration(
                      hintText: "e.g., Downtown Metro Station",
                      border: OutlineInputBorder(),
                    ),
                    enabled: !loading,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: !loading
                      ? () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MapPickerWidget(
                                title: 'Select Start Location',
                                onLocationPicked: (location, address) {
                                  setState(() {
                                    startLocationController.text = address;
                                    startLatController.text =
                                        location.latitude.toString();
                                    startLngController.text =
                                        location.longitude.toString();
                                  });
                                },
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.map),
                  label: const Text("Map"),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Latitude", style: Theme.of(context).textTheme.bodySmall),
                      TextField(
                        controller: startLatController,
                        decoration: const InputDecoration(
                          hintText: "40.7128",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !loading,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Longitude", style: Theme.of(context).textTheme.bodySmall),
                      TextField(
                        controller: startLngController,
                        decoration: const InputDecoration(
                          hintText: "-74.0060",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !loading,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // End Location
            Text("End Location", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: endLocationController,
                    decoration: const InputDecoration(
                      hintText: "e.g., Airport Terminal 1",
                      border: OutlineInputBorder(),
                    ),
                    enabled: !loading,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: !loading
                      ? () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MapPickerWidget(
                                title: 'Select End Location',
                                onLocationPicked: (location, address) {
                                  setState(() {
                                    endLocationController.text = address;
                                    endLatController.text =
                                        location.latitude.toString();
                                    endLngController.text =
                                        location.longitude.toString();
                                  });
                                },
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.map),
                  label: const Text("Map"),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Latitude", style: Theme.of(context).textTheme.bodySmall),
                      TextField(
                        controller: endLatController,
                        decoration: const InputDecoration(
                          hintText: "40.7700",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !loading,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Longitude", style: Theme.of(context).textTheme.bodySmall),
                      TextField(
                        controller: endLngController,
                        decoration: const InputDecoration(
                          hintText: "-73.8740",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !loading,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Departure Date & Time
            Text("Departure", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : () => _selectDate(context),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(selectedDate == null
                        ? "Select Date"
                        : "${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : () => _selectTime(context),
                    icon: const Icon(Icons.access_time),
                    label: Text(selectedTime == null
                        ? "Select Time"
                        : selectedTime!.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Vehicle Infoout 
            Text("Vehicle Information", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedVehicleType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Vehicle Type",
              ),
              items: vehicleTypes
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.toUpperCase()),
                      ))
                  .toList(),
              onChanged: loading ? null : (value) {
                if (value != null) {
                  setState(() => selectedVehicleType = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: vehiclePlateController,
              decoration: const InputDecoration(
                labelText: "Vehicle Plate (Optional)",
                border: OutlineInputBorder(),
                hintText: "e.g., ABC-1234",
              ),
              enabled: !loading,
            ),
            const SizedBox(height: 24),

            // Ride Details
            Text("Ride Details", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: availableSeatsController,
                    decoration: const InputDecoration(
                      labelText: "Available Seats",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !loading,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: pricePerSeatController,
                    decoration: const InputDecoration(
                      labelText: "Price per Seat",
                      border: OutlineInputBorder(),
                      prefixText: "\$",
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !loading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: "Additional Notes (Optional)",
                border: OutlineInputBorder(),
                hintText: "e.g., stops at downtown, music, AC...",
              ),
              maxLines: 3,
              enabled: !loading,
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _submitRide,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Post Ride", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
