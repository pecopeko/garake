# Garake App Architecture

## Goal
- Deliver an iOS-first Garake-style camera/photo editor with a high-fidelity feature-phone UI.
- Keep fast UI iteration by isolating rendering concerns from business logic and plugin integration.

## Layered Structure
- `lib/app/`: root app widget, route map, global theme.
- `lib/core/`: reusable low-level processors (retro filter and sticker compositor).
- `lib/features/editor/domain/`: entities (`EditorSession`, `StickerItem`, `CanvasTransform`) and repository interfaces.
- `lib/features/editor/application/`: controller and immutable state.
- `lib/features/editor/data/`: concrete plugin adapters (`image_picker`, save, share).
- `lib/features/editor/presentation/`: shell UI, canvas, sheets, and user interaction components.

## Dependency Rules
- Presentation can call Application only.
- Application depends on Domain contracts/entities.
- Data implements Domain repository interfaces.
- Core processors implement Domain interfaces and do not import presentation.
- Domain remains framework/plugin-agnostic except geometry primitives (`dart:ui`).

## Main Data Flow
1. `EditorScreen` asks `EditorController.startSession()` from menu selection.
2. `ImageSourceRepository` fetches camera or gallery bytes.
3. `FilterEngine` generates Garake-styled base JPEG with date stamp.
4. `EditorSession` stores original bytes, filtered bytes, sticker list, and `CanvasTransform`.
5. `EditorCanvas` updates sticker positions/scales and pushes current fit transform.
6. Save/share triggers `StickerComposer.compose()` to always build final JPEG output.
7. `ExportRepository` saves to photo library (with fallback path) or opens share sheet.

## Public Interfaces
- `ImageSourceRepository`
  - `pickFromCamera()`
  - `pickFromGallery()`
- `FilterEngine`
  - `applyGarakeFilter(input, config, now)`
- `StickerComposer`
  - `compose(filtered, stickers, stampDate)`
- `ExportRepository`
  - `saveJpeg(bytes)`
  - `shareImage(bytes, {text})`
- `EditorController`
  - `startSession(source)`
  - `addSticker(assetPath)`
  - `updateStickerPosition(id, offset)`
  - `updateStickerScale(id, scale)`
  - `toggleStickerSelection(id)`
  - `deleteSticker(id)`
  - `deleteSelectedSticker()`
  - `updateCanvasTransform(transform)`
  - `saveCurrentImage()`
  - `shareCurrentImage()`

## Coordinate Strategy
- Canvas uses contain-fit math and keeps sticker coordinates normalized to the fitted image rect (not full viewport).
- This prevents preview/export mismatch when viewport and source aspect ratios differ.
- `CanvasTransform` is captured for diagnostics and future UI adaptations.

## Explainability and Limits
- Every Dart file begins with a one-line purpose comment and dependency memo.
- Every Dart file must stay below 500 lines.
