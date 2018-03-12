This repo is a collection of scripts and tools for extracting post and comment karma from subreddits. Collecting data from Reddit via their api has limitations. Any "listing" (posts, comments) can only return a  maximum of 1000 items. In order to extract as much karma as possible, the following method has been used:

### Method

1. Get Top Posts.
   * For `r/ethereum` & `r/ethtrader`, retrieve the top posts (~1000 each).
   * Store users and karma from these posts and their comments
   * Mark users as "uncollected".
2. Get User Content.
   * Retrieve posts & comments, filtering `r/ethereum` & `r/ethtrader`, for each "uncollected" user.
   * Mark these users as "collected".
   * Mark *new* (user, comment parent) posts as "uncollected".
3. Get Posts.
   * Retrieve "uncollected" posts
   * Store users and karma from these posts and their comments
   * Mark these posts as "collected".
4. Repeat 2) & 3) until no "uncollected" users or posts.
