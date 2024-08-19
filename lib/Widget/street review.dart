import 'package:flutter/material.dart';
import 'package:navigation/Model/Streets.dart';
import 'package:get/get.dart';
import 'package:navigation/Getx/euler.dart';
import 'package:navigation/Widget/review.dart';
import 'package:navigation/Utility.dart';
import 'package:navigation/Getx/maps.dart';

class StreetreviewController extends GetxController {
  var selectedStreetIndex = RxInt(-1); // -1 indicates no selection
  var streets = RxList<StreetModel>(); // List of all streets
  final EulerCircuit _eulerCircuit =
  Get.find<EulerCircuit>(); // Access EulerCircuit controller

  void setSelectedStreetIndex(int index) {
    selectedStreetIndex.value = index;
  }

  dynamic findSegment() {
    for (List<dynamic> segment in _eulerCircuit.eulerCircuit.value) {
      Map<String, dynamic> segmentInfo = segment[2];
      if (segmentInfo["id"] == _eulerCircuit.eulerCircuit[_eulerCircuit.currentSegmentIndex.value][2]['id']) {
        return segment[0];
      }
    }
  }


  void ChangeStreetIndex() {
    int currentSegmentIndex = _eulerCircuit.currentSegmentIndex.value;
    for (int i = currentSegmentIndex;
    i < currentSegmentIndex + 3 && i < _eulerCircuit.eulerCircuit.length;
    i++) {
      int streetId = _eulerCircuit.eulerCircuit[i][2]['id'];
      if (streetId == selectedStreetIndex.value) {
        // Check if the next segment exists and has the same ID to decide on increment
        if (i + 1 < _eulerCircuit.eulerCircuit.length && _eulerCircuit.eulerCircuit[i][2]['id'] == _eulerCircuit.eulerCircuit[i + 1][2]['id']) {
          // If the IDs are the same, set index +2 considering the next segment's index but within bounds
          int newIndex = i + 2; // Corrected to increment by 2
          _eulerCircuit.setCurrentSegmentIndex(newIndex < _eulerCircuit.eulerCircuit.length ? newIndex : _eulerCircuit.eulerCircuit.length - 1);
        } else {
          // If not, just increment the index by +1 as usual
          _eulerCircuit.setCurrentSegmentIndex(i + 1);
        }
        break; // Break the loop once the index is set
      }
    }
  }


  StreetModel? findStreetById(int searchId) {
    for (var street in streets) {
      if (street.streetId == searchId) {
        return street;
      }
    }
    return null;
  }

  void initializeStreets(List<StreetModel> streetData) {
    streets.assignAll(streetData);
  }

  void resetSelectedStreetIndex() {
    selectedStreetIndex.value = -1;
  }

  List<StreetModel> getVisibleStreets() {
    int currentSegmentIndex = _eulerCircuit.currentSegmentIndex.value;
    if (currentSegmentIndex < 0 ||
        currentSegmentIndex >= _eulerCircuit.eulerCircuit.length) return [];

    List<StreetModel> visibleStreets = [];

    // Loop through the Euler circuit starting from the current segment
    for (int i = currentSegmentIndex;
    i < currentSegmentIndex +  6 && i < _eulerCircuit.eulerCircuit.length;
    i++) {
      int streetId = _eulerCircuit.eulerCircuit[i][2]['id'];
      StreetModel? street = findStreetById(streetId);
      if (street != null && !visibleStreets.contains(street)) {
        visibleStreets.add(street);
      }
    }
    return visibleStreets;
  }
}

class StreetItemWidget extends StatelessWidget {
  final StreetModel street;
  final VoidCallback onDelete;
  final VoidCallback? onNavigate;
  final bool isSelected;
  final IconData deleteIcon;
  final bool showNavigateButton;

  StreetItemWidget({
    Key? key,
    required this.street,
    required this.onDelete,
    this.onNavigate,
    this.isSelected = false,
    this.deleteIcon = Icons.delete,
    this.showNavigateButton = false,
  }) : super(key: key);

  final StreetreviewController _controller = Get.find<StreetreviewController>();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        _controller.setSelectedStreetIndex(street.streetId!);
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "ID: ${street.streetId}",
                  style: TextStyle(fontSize: 10), // Adjust font size as needed
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showNavigateButton)
                IconButton(
                  icon: Icon(Icons.directions, size: 10),
                  onPressed: onNavigate,
                ),
              IconButton(
                icon: Icon(deleteIcon, size: 10),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class StreetListView extends StatelessWidget {
  final StreetreviewController _controller = Get.find<StreetreviewController>();
  final EulerCircuit _eulerCircuit = Get.find<EulerCircuit>();
  final LocationController _locationController = Get.find<LocationController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      var streets = _controller.getVisibleStreets();
      return Container(
        width: MediaQuery.of(context).size.width * 0.5,
        // Removed fixed height to let the ListView naturally size itself
        child: ListView.builder(
          shrinkWrap: true,  // Helps the ListView to take only necessary space
          itemCount: streets.length + 1, // +1 for the reset option
          itemBuilder: (context, index) {
            if (index == 0) {
              return InkWell(
                onTap: () => _controller.resetSelectedStreetIndex(),
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Reset Selection', style: TextStyle(fontSize: 8)),
                  ],
                ),
              );
            } else {
              final street = streets[index - 1];
              bool isSelected = (index - 1) == _controller.selectedStreetIndex.value;
              return StreetItemWidget(
                street: street,
                onDelete: () => deleteStreet(street),
                onNavigate: index == 1 ? () => navigateToStreet() : null, // Pass the navigateToStreet callback only for the first street item
                isSelected: isSelected,
                deleteIcon: Icons.delete_forever,
                showNavigateButton: index == 1, // Show navigate button only for the first item
              );
            }
          },
        ),
      );
    });
  }
  void navigateToStreet() {
    _eulerCircuit.addCurrentSegmentIndex();
    _controller.resetSelectedStreetIndex();
  }

  void deleteStreet(StreetModel street) {
    _controller.ChangeStreetIndex();
    showReasonPopup();
    dynamic variable = _controller.findSegment();
    if (variable != null && variable.length > 1) {
      openMapWithDirections(_locationController.currentLocation.value.latitude, _locationController.currentLocation.value.longitude, variable[0], variable[1]);
    } else {
      // Handle the case where variable is null or doesn't have the expected data
      print('Error: Segment data is unavailable.');
    }
  }

}


