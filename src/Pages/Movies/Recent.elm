module Pages.Movies.Recent exposing (Model, Msg, Params, page)

import Colors exposing (greyIcon)
import Components.SectionHeader
import Components.VerticalNav
import Components.VerticalNavMovies
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events
import Element.Font as Font
import Element.Input as Input
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
import Svg.Attributes
import Url exposing (percentEncode)
import Url.Builder exposing (crossOrigin)
import WSDecoder exposing (ItemDetails, MovieObj)



--import MovieItem exposing ()
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
    , movie_list : List MovieObj
    , route : Route
    }


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared url =
    ( { currentlyPlaying = shared.currentlyPlaying, movie_list = shared.movie_list, route = url.route }
    , sendAction """{"jsonrpc": "2.0", "method": "VideoLibrary.GetMovies", "params": { "filter": {"field": "playcount", "operator": "is", "value": "0"}, "properties" : ["art", "rating", "thumbnail", "playcount", "file","year","dateadded"], "sort": { "order": "ascending", "method": "label", "ignorearticle": true } }, "id": "libMovies"}"""
    )



-- UPDATE


type Msg
    = SetCurrentlyPlaying MovieObj
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetCurrentlyPlaying movie ->
            ( model
            , sendActions
                [ {- clear the queue -} """{"jsonrpc": "2.0", "id": 0, "method": "Playlist.Clear", "params": {"playlistid": 0}}"""
                , {- add the next movie -} """{"jsonrpc": "2.0", "id": 1, "method": "Playlist.Add", "params": {"playlistid": 0, "item": {"movieid": """ ++ String.fromInt movie.movieid ++ """}}}"""
                , {- play -} """{"jsonrpc": "2.0", "id": 0, "method": "Player.Open", "params": {"item": {"playlistid": 0}}}"""
                ]
            )

        NoOp ->
            ( model, Cmd.none )


save : Model -> Shared.Model -> Shared.Model
save model shared =
    { shared | currentlyPlaying = model.currentlyPlaying, movie_list = model.movie_list }


load : Shared.Model -> Model -> ( Model, Cmd Msg )
load shared model =
    ( { model | movie_list = shared.movie_list }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


materialButton : ( Icon msg, msg ) -> Element msg
materialButton ( icon, action ) =
    Input.button [ paddingXY 5 3, Background.color (rgb 0.2 0.2 0.2) ]
        { onPress = Just action
        , label = Element.html (icon 24 (MITypes.Color <| greyIcon))
        }


constructMovieItem : MovieObj -> Element Msg
constructMovieItem movie =
    column [ spacingXY 5 0, Element.width fill, Element.height fill ]
        [ image
            [ Element.width (fill |> minimum 150 |> maximum 150)
            , Element.height (fill |> minimum 200 |> maximum 200)
            , inFront
                (row []
                    [ materialButton ( Filled.play_arrow, NoOp ) ]
                )

            {- , Element.Events.onMouseEnter ShowMenu
               , Element.Events.onMouseLeave CloseMenu
            -}
            ]
            (if String.isEmpty movie.thumbnail then
                { src = "/thumbnail_default.png"
                , description = "Hero Image"
                }

             else
                { description = movie.label
                , src = crossOrigin "http://localhost:8080" [ "image", percentEncode movie.thumbnail ] []
                }
            )
        , column [ alignBottom, Background.color (rgb 1 1 1), Element.width (fill |> minimum 150 |> maximum 150), clip ]
            [ el [ Font.color (Element.rgb 0 0 0), Font.size 18 ] (Element.text movie.label)
            , el [ Font.color (Element.rgb 0.6 0.6 0.6), Font.size 18 ] (Element.text "2020")
            ]
        ]



-- VIEW


view : Model -> Document Msg
view model =
    { title = "Movies"
    , body =
        [ row [ Element.height fill, Element.width fill ]
            [ Components.VerticalNavMovies.view model.route
            , column [ Element.height fill, Element.width (fillPortion 6), spacingXY 5 7, Background.color Colors.background ]
                [ column [ Element.height fill, Element.width fill ]
                    [ Components.SectionHeader.view "Recently Added Movies"
                        Nothing
                        False
                        []
                    , wrappedRow [ Element.height fill, Element.width (fillPortion 6), Background.color (rgb 0.8 0.8 0.8), spacingXY 5 10 ]
                        (List.map
                            (\movie ->
                                constructMovieItem movie
                            )
                            model.movie_list
                        )
                    ]
                , column [ Element.height fill, Element.width fill ]
                    [ Components.SectionHeader.view "All Movies"
                        Nothing
                        False
                        []
                    , wrappedRow [ Element.height fill, Element.width (fillPortion 6), Background.color (rgb 0.8 0.8 0.8), spacingXY 5 10 ]
                        (List.map
                            (\movie ->
                                constructMovieItem movie
                            )
                            model.movie_list
                        )
                    ]
                ]
            ]
        ]
    }
