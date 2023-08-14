{- Checks system configuration and generates Build/SysConfig. -}

{-# OPTIONS_GHC -fno-warn-tabs #-}

module Build.Configure where

import Build.TestConfig
import Utility.Env.Basic
import qualified Git.Version

import Control.Monad

tests :: [TestCase]
tests =
	[ TestCase "git" $ testCmd "git" "git --version >/dev/null"
	, TestCase "git version" getGitVersion
	]

getGitVersion :: Test
getGitVersion = go =<< getEnv "FORCE_GIT_VERSION"
  where
	go (Just s) = return $ Config "gitversion" $ StringConfig s
	go Nothing = do
		v <- Git.Version.installed
		let oldestallowed = Git.Version.normalize "2.1"
		when (v < oldestallowed) $
			error $ "installed git version " ++ show v ++ " is too old! (Need " ++ show oldestallowed ++ " or newer)"
		return $ Config "gitversion" $ StringConfig $ show v

run :: [TestCase] -> IO ()
run ts = do
	config <- runTests ts
	writeSysConfig config
