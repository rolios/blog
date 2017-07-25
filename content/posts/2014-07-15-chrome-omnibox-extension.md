---
title: Chrome omnibox extension
subtitle: how-to: haskell inspector extension
description: Some months ago, I developed (for fun) a Google Chrome extension to search in haskell documentation directly from the chrome search bar. The development was pretty easy and cool, that's why I wanted to describe it here.
---
**NB**: *This blog post was written in 2014 and might be deprecated.*

Some months ago, I developed (for fun) a Google Chrome extension to search in haskell documentation directly from the chrome search bar. The development was pretty easy and cool, that's why I wanted to describe it here.

I started by looking the code of a similar plugin I'm used to, the Android SDK Search extension from Roman Nurik, [available on Github](https://github.com/romannurik/AndroidSDKSearchExtension). The code is clear and instructive. I was about to tweak it to reach my own goal, but finally it was doing too much things for me.

Then I took a look at [the documentation](https://developer.chrome.com/extensions/overview), and realized that contributing to search results from the search bar is well supported, with the [omnibox api](https://developer.chrome.com/extensions/omnibox). The [sample provided](https://developer.chrome.com/extensions/samples#omnibox-example) is also a good starter point.

The very first thing we need is a **_manifest.json_**. This file describe all the properties of our extension in a json format. Here we go:

	{
	  "manifest_version": 2,
	  "name": "Haskell inspector",
	  "description": "Adds an '>>' omnibox command and find results from hoogle, hackage",
	  "version": "1.0",
	  "author": "Gonthier Olivier",
	  "icons": {
	    "16": "icons/16.png",
	    "32": "icons/32.png",
	    "128": "icons/128.png"
	  },
	}

In this first version I only wrote basic informations that describes my app. These informations will be used by the chrome store later. In the description, I specify an _"omnibox command"_. The omnibox feature actually  works with a command: in this case, when I will type **_'>>' + TAB_** in the search bar, it will activate my extension. To declare this command, I just have to add an omnibox field in my manifest.

    "omnibox": {
        "keyword": ">>"
    },

Ok, now we're ready to develop the logic behing it, using javascript.

	chrome.omnibox.onInputChanged.addListener(function(text, suggest) {

	});

	chrome.omnibox.onInputEntered.addListener(function(text) {

	});

 I started by registering  two event listeners: the first one will be called when the user type in the search input, and the second one is used when he validate his search. Let's start with the input changed event.

 When this event occurs, I want to get the actual text typed, request the [hoogle website](http://www.haskell.org/hoogle/) with this text in search parameter, and then parse the result. To understand how I can parse it, I examine a sample page with my browser developer console. I tested with [www.haskell.org/hoogle/?hoogle=test](www.haskell.org/hoogle/?hoogle=test), and found the recurring elements I needed. Also, I use jQuery to simplify the work on parsing and requesting.

	 chrome.omnibox.onInputChanged.addListener(function(text, suggest) {
	    if(!text) return;
	    $.ajax({
	        url:'http://haskell.org/hoogle?hoogle='+text,
	        type:'get',
	        dataType:'xml',
	        success: function(data){
			    var suggestionArray = parseHooglePage(data)
	            suggest(suggestionArray);
	        }
	    });
	});

Chrome gave me two useful parameters: **_text_** is the actual text typed by the user, and **_suggest_** is a fonction taking an array in parameter, with all the search result we will suggest to the user! With **$.ajax** I do the request, in case of success I parse the page, and use the suggest function to display result. Here is the parsing function:

	function parseHooglePage(data) {
	    var suggestions = $('.ans', data);
	    var suggestionsMap = suggestions.map(function(_, sugg){
			var from = $(sugg, data)
			  .next().filter('.from').html();
			var link = $('a.a', sugg).attr('href');
			var text = $(sugg).html();
			text = text.replace(/<(\/)?b>/g, '<$1match>');
			if(from)
			    text = text + " <dim> - "+from+"</dim>";
			return {content: link, description: text}
	    });
	    return suggestionsMap.toArray();
	}

I will not describe this part in details, since it's very specific to the page I'm parsing. Basically, I found that every entries have a **_.ans_** class, so I can take all tags makred with this class, and iterate over them to get the content I need: a link, a text and a package source if any. To do that, I use the map function from jQuery.

This function returns an array of objects like this:

	{
	  "content": "http://hackage.haskell.org/packages/archive/base/latest/doc/html/Control-Monad.html#v:join",
	  "description": "<match>join</match> :: Monad m => m (m a) -> m a<dim> - base Control.Monad</dim>"
	}

This format is specified [here](https://developer.chrome.com/extensions/omnibox#type-SuggestResult). You may have notice the use of a specific markup in the description text. As described by the doc, you can use **_< url >_** to add links, **_< match >_** to highlight text searched by the user, and **_< dim >_** to give more indications on the result.

Ok, at this point we are able to suggest results to the user. Now, what happens if he type _enter_ on something we suggested?

Guess what: it calls the second event, the one called **_onInputEntered_**. With this event, the url is passed in parameter. Now, we just have to navigate to this url, and we can do it using the chrome api:

	chrome.omnibox.onInputEntered.addListener(function(url) {
		chrome.tabs.query({
	        active: true,
	        currentWindow: true
	    }, function(tabs) {
	        chrome.tabs.update(tabs[0].id, {
	            url: url
	        });
	    });
	});

And that's it! If you missed something, you can find the complete code on [github](https://github.com/OlivierGonthier/haskell-chrome-inspector/).

 To test it, just do a zip archive containing your script and your manifest, and visit [chrome://extensions/](chrome://extensions/) to activate your extension. If you're happy with it, you can then publish your extension on [the store](https://chrome.google.com/webstore/developer/dashboard).

Great, isn't it?
