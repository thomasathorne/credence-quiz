{-# LANGUAGE TemplateHaskell, GeneralizedNewtypeDeriving #-}

module Logic where

import Data.Map (Map)
import qualified Data.Map as M
import Control.Lens
import Control.Applicative
import Control.Monad.State
import qualified Data.Text as T
import Network.HTTP.Conduit

data Answer = A | B deriving (Show, Eq)

data Question = Question { qText, aText, bText :: T.Text,
                           answer :: Answer }
  deriving (Show, Eq)

instance Show Manager where
  show m = "(Manager)"
data GameState = GameState { _answers :: Map Int Int,
                             _score :: Double,
                             _manager :: Manager }
  deriving (Show)

makeLenses ''GameState

newtype Game a = Game {game :: StateT GameState IO a}
  deriving (Functor, Applicative, Monad, MonadState GameState, MonadIO)

runGame :: Game a -> IO (a, GameState)
runGame g = runStateT (game g) initial

initial :: GameState
initial = undefined & answers .~ M.empty & score .~ 0

question :: Question -> Int -> Game ()
question (Question q a b answer) credence = do
  userAnswer <- liftIO $ do
    putStrLn $ T.unpack q
    putStrLn $ "A) " ++ T.unpack a
    putStrLn $ "B) " ++ T.unpack b
    getUserAnswer
  if answer == userAnswer
    then answers.at credence.non 0 += 1
    else answers.at (100 - credence).non 0 += 1

getUserAnswer :: IO Answer
getUserAnswer = do
  s <- getLine
  case s of
    "A" -> return A
    "B" -> return B
    "a" -> return A
    "b" -> return B
    _ -> do putStrLn "Don't understand, please try again."
            getUserAnswer

countScore :: Map Int Int -> Double
countScore m = let l = M.toList m
               in sum $ flip map l $ \(cr, n) ->
                    100 * fromIntegral n * logBase 2 (fromIntegral cr / 50)
