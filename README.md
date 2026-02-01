A modern Flutter application designed to help users create, store, and manage important travel documents such as passports, CNICs, visas, and IDs with expiration tracking and image upload support.

This project focuses on clean UI, scalable logic separation, and real-world mobile app architecture.

The main goals behind this project were:

Build a real production-style Flutter app

Separate UI and business logic

Handle permissions safely

Implement image upload functionality

Add document expiry tracking

Maintain clean architecture

UI Layer (Presentation)

Responsible for:

Displaying screens

User interaction

Navigation

Logic Layer (Services & Utilities)

Used to keep business logic separate from UI.

Purpose:

Handle camera/gallery access

Manage permissions

Return selected image file

Benefits:

UI stays clean

Reusable image picking logic

Easier debugging

User Opens Create Document Screen

User sees:

Document name field

Holder name field

Issue date picker

Expiry date picker

Upload image section

Date Selection Flow

State updates

Image Upload Flow

When user taps upload box:

Tap → ImagePickerService → Permission Check → Gallery Open → File Selected → Preview Displayed


Permission handling:

Automatically requests permission

Stops flow if denied

Prevents crashes

Preview System

Once image is selected:

It is displayed inside UI

Rounded UI preview

Optimized resolution and compression 


