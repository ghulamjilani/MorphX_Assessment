Q:
Hello Bitly!

I couldn't find anything in your API docs on how to check that Branded Bitlinks current limit via API calls.
Can you confirm that it is not currently possible?

The reason why I need it is because our application needs to be aware of this limit to decide whether to do another shortening call or wait. Until it is possible we're forced to generate bit.ly links(not branded ones) even when we don't need it just to see if we're still in that Branded Bitlinks limit



---

Hi Nikita,

At this time we do not have an API endpoint available for checking on rate limits. We are discussing adding such information to our API in the future. In the meantime, the limit is 500 branded Bitlinks created per calendar month, so we suggest as a temporary measure that you count the number of branded Bitlinks you create, and decide what to do based on your current count.
