// Every user-facing string in the guide. README.md copies these verbatim; check-copy.mjs lints them
// against WordFlora/Rules/CopySafety.swift plus the extra words the brief bans (locked, lock, unlock, lose).
const GUIDE_COPY = {
  ui: {
    skip: 'Skip',
    close: 'Close',          // replay from Settings: replaces Skip
    back: 'Back',
    next: 'Next',
    start: 'Start playing',  // first run, page 8
    done: 'Done',            // replay from Settings, page 8
    dots: 'Page {n} of {total}',
    settingsRow: 'Show the guide again',
    skipHint: 'Goes straight to your first word',
    closeHint: 'Back to Settings',
    dotsLabel: 'Guide',
    settingsFoot: 'A quick tour of how to play and grow your garden.',
  },
  pages: [
    { id: 'guess', title: 'Guess the word',
      lines: ['Read the clue, then tap letters to fill in the word.',
              'Your flower’s petals are your tries. Tap Help for a hint.'],
      art: 'A flower with 6 of 8 petals, the word D, A, blank, S, blank, and a Help button.' },
    { id: 'plants', title: 'Three words, one plant',
      lines: ['Your first win brings your first plant.',
              'After that, every 3 words brings a new plant.'],
      art: 'Three words with check marks lead to a new daisy in a pot.' },
    { id: 'tend', title: 'Help your plant grow',
      lines: ['Water, feed and sun help it grow a little each day.',
              'Prune and repot to help it reach full bloom.'],
      art: 'A plant growing from tiny to full bloom, with water, feed, sun, prune and repot buttons.' },
    { id: 'love', title: 'Hearts and hellos',
      lines: ['Say hello or care for your plant each day to fill its energy hearts.',
              'After a few rainy days it naps as a seed. A fun challenge wakes it, and it keeps all it grew.'],
      // Quiet Garden or Calm mode on: plants never rain or nap, so line 2 changes.
      linesQuiet: ['Say hello or care for your plant each day to fill its energy hearts.',
                   'Your plant keeps all it grows, always.'],
      art: 'A plant with 4 of 5 energy hearts saying hello. Below, a seed napping in its pot wakes up as a sprout.' },
    { id: 'garden', title: 'Your garden and friends',
      lines: ['Visit all your plants in the Garden.',
              'Catch butterflies to meet visitors and earn points for Shed tools.'],
      art: 'Garden, Visitors and Shed, with a butterfly flying from Visitors to the Shed.' },
    { id: 'daily', title: 'One word for everyone',
      lines: ['Daily Bloom is a new word each day.',
              'Everyone who plays gets the same word that day.'],
      art: 'The Daily Bloom card with a sunflower and five mystery letters.' },
    { id: 'levels', title: 'Five levels to explore',
      lines: ['Find 10 plants in a level to open the next one.',
              'Grow all 10 to full bloom for a gold ring.'],
      art: 'A garden path with five levels: Seedling, Sprout, Wildwood, Grove and Ancient. The first has a gold ring.' },
    { id: 'peeks', title: 'Coming soon in your garden',
      lines: ['Rare plants from far away, new pots and shiny badges.',
              'They open up as your garden grows. Let’s play!'],
      art: 'Sneak peeks: a rare plant, a starry pot and a badge, each with a Soon tag.' },
  ],
  // Small words drawn inside the illustrations (also linted).
  artText: ['Clue', 'A white flower with a sunny middle', 'Help', 'Petals = tries', 'New plant found!',
    'word', 'Tiny', 'Sprout', 'Bud', 'Bloom', 'Full bloom', 'Water', 'Feed', 'Sun', 'Prune', 'Repot', 'Hello!',
    'Energy', 'Naps as a seed', 'Wakes with a challenge', 'Garden', 'Shed', 'Visitors', 'points',
    'Daily Bloom', 'One word for everyone today', 'Seedling', 'Wildwood', 'Grove', 'Ancient', 'Gold ring = full bloom',
    '10 plants opens the next level', 'You are here', 'Soon', 'Rare plants', 'Pots', 'Badges', 'Level 5'],
};
if (typeof module !== 'undefined') module.exports = GUIDE_COPY;
