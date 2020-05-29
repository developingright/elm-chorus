module Pages.Help exposing (Flags, Model, Msg, page)

import Element
import Page exposing (Document, Page)


type alias Flags =
    ()


type alias Model =
    ()


type alias Msg =
    Never


page : Page Flags Model Msg
page =
    Page.static
        { view = view
        }


view : Document Msg
view =
    { title = "Help"
    , body = [ Element.text "Help" ]
    }