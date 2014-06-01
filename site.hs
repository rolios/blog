--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Data.List              (sortBy,isInfixOf)
import           System.FilePath.Posix  (takeBaseName,takeDirectory,(</>),splitFileName)
import           Hakyll


--------------------------------------------------------------------------------
feedConfiguration :: FeedConfiguration
feedConfiguration = FeedConfiguration
  { feedTitle = "todo.com"
  , feedDescription = "rolios mind blog"
  , feedAuthorName = "Olivier Gonthier"
  , feedAuthorEmail = "o.gonthier@gmail.com"
  , feedRoot = "http://r0ly.fr"
  }
  
--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
    match (    "img/**"
          .||.  "js/**"
          .||.  "css/fonts/*"
          .||.  "files/**"
          .||.  "CNAME")
          staticBehavior     
          
    -- Compressed SASS (add potentially included files)
    sassDependencies <- makePatternDependency "css/include/*.sass"
    rulesExtraDependencies [sassDependencies] $ do
        match "css/*" $ do
            route   $ setExtension "css"
            compile $ getResourceString >>=
                      withItemBody (unixFilter "sass" ["--trace"]) >>=
                      return . fmap compressCss


    match "content/posts/*" $ do
        route $ postRoute
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    create [fromFilePath ("feed.xml")] (feedBehavior)
    
    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- (fmap (take 4)) . recentFirst =<< loadAll "content/posts/*"
            let indexCtx =
                    listField "posts" postCtx (return posts) `mappend`
--                     constField "title" "Recent "                `mappend`
                    defCtx
            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls
                >>= removeIndexHtml
                
    match "about.html" $ do
	route niceRoute
	compile $ do
	    getResourceBody
		>>= loadAndApplyTemplate "templates/default.html" defaultContext
		>>= relativizeUrls
		>>= removeIndexHtml
    
    match "archives.html" $ do
    route niceRoute
    compile $ do
	posts <- recentFirst =<< loadAll "content/posts/*"
	let archCtx =
		listField "posts" postCtx (return posts) `mappend`
		defCtx
	getResourceBody
	    >>= applyAsTemplate archCtx
	    >>= loadAndApplyTemplate "templates/default.html" archCtx
	    >>= relativizeUrls
	    >>= removeIndexHtml

    match "templates/*" $ compile templateCompiler

-------------------------------------------------------------------------------- 
                      
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext

defCtx :: Context String
defCtx =
    defaultContext
    
staticBehavior :: Rules ()
staticBehavior = do
  route   idRoute
  compile copyFileCompiler
  
--------------------------------------------------------------------------------
  
feedBehavior :: Rules ()
feedBehavior = do
      route idRoute
      compile $ do
	renderAtom feedConfiguration defCtx =<< (fmap (take 10)) . recentFirst =<< loadAll "content/posts/*"
	
--------------------------------------------------------------------------------
--
-- replace url of the form foo/bar/index.html by foo/bar
removeIndexHtml :: Item String -> Compiler (Item String)
removeIndexHtml item = return $ fmap (withUrls removeIndexStr) item

removeIndexStr :: String -> String
removeIndexStr url = case splitFileName url of
    (dir, "index.html") | isLocal dir -> dir
                        | otherwise   -> url
    _                                 -> url
    where isLocal uri = not (isInfixOf "://" uri)

--------------------------------------------------------------------------------
--
-- replace a foo/bar.md by foo/bar/index.html
-- this way the url looks like: foo/bar in most browsers
niceRoute :: Routes
niceRoute = customRoute createIndexRoute
  where
    createIndexRoute ident = takeDirectory p </> takeBaseName p </> "index.html"
                             where p=toFilePath ident

postRoute :: Routes
postRoute = customRoute createIndexRoute
  where
    createIndexRoute ident = removeDate (takeBaseName p) </> "index.html"
                             where p=toFilePath ident
				  
removeDate :: FilePath -> FilePath
removeDate = drop 11
