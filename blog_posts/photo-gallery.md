---
title: Building a photo gallery layout
published_at: 3/8/26 9:48
tags: code, javascript, web
---

In 2023 my brother-in-law gifted me a [FED-2](https://en.wikipedia.org/wiki/FED_2), an old Soviet film camera from the 50s.
Photography was a hobby I'd bounced off a few times, but I'd never shot film, let alone on a fully manual analog camera.
My first few rolls were rough, but even the mistakes and imperfections were inspiring.
I was hooked.

Since then, I've accumulated a decent amount of photos I'm proud enough of to share with the world.
Social media websites were frustrating in that they would compress my images in unflattering ways and tended to use layouts that would crop out important parts of my compositions.
Dedicated photography sites were a bit better, but I got no control over how my work was presented, and most gated important features behind paid subscriptions.

I know a thing or two about building websites, I thought to myself.
How hard could it be to design my perfect photo gallery?

## The layout

Ideally, my photos can be displayed in the ordering of my choosing from a wide range of formats and aspect ratios.
Most photo galleries use a row-based layout, with each having its own column choices to preserve the aspect ratio of each photo.
It looks really nice!

![screenshot of my photo gallery, showing off the layout](/assets/photo-gallery/gallery.webp "The goal")

Early attempts to replicate this in pure CSS didn't get very far; while it can express some constraints well, this style of layout requires an iterative algorithm (at least, until the [masonry layout spec](https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Grid_layout/Masonry_layout) gains wider adoption).
The requirements bear some resemblance to [rectangle packing](https://en.wikipedia.org/wiki/Rectangle_packing), albeit a much simpler and constrained version of it.

## The algorithm

Before we get too far, let's break down our constraints:

- The container width is fixed
- Each image has a known aspect ratio
- The height of any given row can be different
- Rows have a max-height before they start looking silly. Let's codify that.
- Images are in a set order

Let's start with an row and add our first image to it.
Because there's no other images, we set its width to the remaining width of the container, which happens to be the full width since it's empty.

![row with a single image](/assets/photo-gallery/step1.svg "Hmmmm that doesn't seem like it'll fit")

Even at a fraction of the width, we've exceeded our maximum height.
Let's add another!

![row with two images](/assets/photo-gallery/step2.svg "Looks like there's still room")

This process is repeated until we find a combination of image aspect ratios that fit within our max-height.
Because the total container height is only constrained by this maximum, there will always be some combination of aspect ratios that will fill the full width of the row.

Expressed mathematically, the required height for a given set of photos in a row is the container width divided by sum of their aspect ratios (taking into account any gaps between photos).
Translated into JS you end up with an iterative process like so:

```js
const grid = [newRow()];
let currentRow = 0;
photos.forEach((photo) => {
  const row = grid[currentRow];
  const aspectRatio = row.aspectRatio + photo.aspectRatio;
  row.aspectRatio = aspectRatio;
  row.photos.push(photo);

  const height = rowWidth(row.photos) / aspectRatio;
  if (height <= MAX_HEIGHT) {
    currentRow += 1;
    grid[currentRow] = newRow();
    return;
  }
});
```

## Optimization

Algorithmic layout should always be a last resort; whenever we sidestep traditional CSS methods for layout we've inserted ourselves into the hot path for rendering.
We need to be able to handle resizing efficiently and fluidly, and avoid expensive cascading layout shifts as we apply our new new calculations.

Inspecting popular photo sites like Flickr that use a similar layout, you'll find each photo pulled out of the cascade and positioned within the container very precisely with inline `transform` styles translating each into their slots.
This is really smart; any layout shifts are fully handled by their JS and all rendering takes place on the browser's compositor, avoiding layout recalculations.
Unfortunately, this also means the entire grid has to be recalculated for every single movement, and shifts from changes like browser resizing are jagged as the window repaints then applies the algorithm to the already rendered elements.

I opted for a hybrid approach; our algorithm is responsible for placing photos into individual rows by calculating and setting their height, but how the photos fit into each row is derived wholly from CSS rules.
Individual images receive an inline style with their `aspect-ratio` and `height` set, and flexbox wrapping ensures the list of photos are rendered appropriately as rows.
That's it!

Our images now take full advantage of the browser's layout engine, and while the heights are static, container size transitions that occur before the algorithm is re-run are as immediate as possible and look natural.
We still need to make sure the distribution of rows fits into the new size and assign new heights as content shifts, so we use a  [ResizeObserver](https://developer.mozilla.org/en-US/docs/Web/API/ResizeObserver) to fire updates in a performant manner that the browser can further optimize before painting.
To make the initial render feel cleaner and avoid layout churn as photos are packed into rows, we can set each photo to `display: none;` in CSS, then set each to `display: initial;` once we've completed our layout.
