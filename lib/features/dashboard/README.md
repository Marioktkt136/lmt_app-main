# Shared Files / Dashboard Feature (`lib/features/dashboard`)

Manages team shared files, scripts, PDFs, Word/Excel sheets, paperwork, images, and external hyperlink cards.

## Rules & Behavior
- Admins and Editors can upload real files from device storage (`NativeMediaService.pickDeviceFile`) or create hyperlink cards.
- Downloading any file saves it directly to the phone's public `Download/LMT` folder (`/storage/emulated/0/Download/LMT/<fileName>`) via `MediaStore.Downloads` and opens it with `OpenFilex`.

## Structure
- `cubit/shared_files_cubit.dart`: `SharedFilesCubitMixin` add/delete operations.
- `views/dashboard_screen.dart`: Category filter chips, search bar, hyperlink cards grid, and documents list.
- `widgets/hyperlink_card_widget.dart`: Interactive card for external URLs and internal routes (`Khelwa`, `YouTube`).
- `widgets/shared_document_tile.dart`: Document row with preview, download, and delete actions.
- `widgets/upload_shared_file_sheet.dart`: Bottom sheet for picking files from phone storage and uploading.
- `widgets/file_preview_sheet.dart`: Preview modal and public `Download/LMT` saver.
