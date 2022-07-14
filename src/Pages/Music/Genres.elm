module Pages.Music.Genres exposing (Model, Msg, Params, page)

import Colors exposing (greyIcon, greyscaleGray)
import Components.VerticalNav
import Components.VerticalNavMusic
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events
import Element.Font as Font
import Element.Input as Input
import Helper exposing (durationToString)
import Html exposing (..)
import Html.Attributes exposing (..)
import Material.Icons as Filled
import Material.Icons.Types as MITypes exposing (Icon)
import Request
import Shared exposing (sendAction, sendActions)
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route exposing (Route)
import Spa.Page as Page exposing (Page)
import Spa.Url as Url exposing (Url)
import Svg.Attributes exposing (alignmentBaseline)
import Url exposing (percentEncode)
import WSDecoder exposing (ItemDetails, SongObj)



--import Components exposing ()


page : Page Params Model Msg
page =
    Page.application
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        , save = save
        , load = load
        }



-- INIT


type alias Params =
    ()


type alias Model =
    { currentlyPlaying : Maybe ItemDetails
    , genre_list : List String
    , route : Route
    }


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared url =
    ( { currentlyPlaying = shared.currentlyPlaying, genre_list = shared.genre_list, route = url.route }
    , sendAction """{"jsonrpc": "2.0", "method": "AudioLibrary.GetSongs", "params": { "limits": { "start" : 0, "end": 25 }, "properties": [ "artist", "duration", "album", "track" ], "sort": { "order": "ascending", "method": "track", "ignorearticle": true } }, "id": "libSongs"}"""
    )



-- UPDATE


type Msg
    = SetCurrentlyPlaying SongObj


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetCurrentlyPlaying song ->
            ( model
            , sendActions
                [ {- clear the queue -} """{"jsonrpc": "2.0", "id": 0, "method": "Playlist.Clear", "params": {"playlistid": 0}}"""
                , {- add the next song -} """{"jsonrpc": "2.0", "id": 1, "method": "Playlist.Add", "params": {"playlistid": 0, "item": {"songid": """ ++ String.fromInt song.songid ++ """}}}"""
                , {- play -} """{"jsonrpc": "2.0", "id": 0, "method": "Player.Open", "params": {"item": {"playlistid": 0}}}"""
                ]
            )


save : Model -> Shared.Model -> Shared.Model
save model shared =
    shared


load : Shared.Model -> Model -> ( Model, Cmd Msg )
load shared model =
    ( { model | genre_list = shared.genre_list }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


materialButton : ( Icon msg, msg ) -> Element msg
materialButton ( icon, action ) =
    Input.button [ paddingXY 5 3 ]
        { onPress = Just action
        , label = Element.html (icon 24 (MITypes.Color <| greyIcon))
        }



-- VIEW


view : Model -> Document Msg
view model =
    { title = "Music.Genres"
    , body =
        [ row [ Element.height fill, Element.width fill ]
            [ Components.VerticalNavMusic.view model.route
            , wrappedRow [ Element.height fill, Element.width (fillPortion 6), Background.color Colors.background, paddingXY 20 15, spacingXY 10 7 ]
                (model.genre_list
                    |> List.sort
                    |> List.map
                        (\genre ->
                            column
                                [ Border.glow Colors.black 0.04
                                , Background.color Colors.white
                                , mouseOver [ Background.color Colors.sidebar ]
                                , Element.height (fill |> minimum 50 |> maximum 50)
                                , Element.width (fill |> minimum 185 |> maximum 185)
                                , Border.rounded 1
                                ]
                                [ Element.link [ Element.width fill, Element.height fill, paddingXY 7 16 ]
                                    { url = Route.toString (Route.Music__Genre__Genre_String { genre = percentEncode genre })
                                    , label = Element.text genre
                                    }
                                ]
                        )
                )
            ]
        ]
    }
