module Lofi.Schema.Output.Joi exposing
  ( createSchemaCode
  )

{-|

# Functions
@docs createSchemaCode
-}

import Lofi.Schema exposing (Schema, Item, Kind(..))
import String.Extra exposing (underscored, camelize, decapitalize, quote)


lowerCamelize : String -> String
lowerCamelize = camelize >> decapitalize

pairsToJSObject : Bool -> List (String, String) -> String
pairsToJSObject multilined pairs =
  let
    propertyDivider =
      if multilined then ",\n  " else ", "
    
    wrapInBraces =
      if multilined then
        \s -> "{\n  " ++ s ++ "\n}"
      else
        \s -> "{ " ++ s ++ " }"
  in
    pairs
    |> List.map (\(a, b) -> a ++ ": " ++ b)
    |> String.join propertyDivider
    |> wrapInBraces

createSchemaCodeFold : Item -> List (Int, (String, String)) -> List (Int, (String, String))
createSchemaCodeFold item list =
  let
    nativeKind =
      case item.kind of
        Text { maximumLength, isEmail } ->
          let
            emailSuffix =
              if isEmail then
                ".email()"
              else
                ""
            
            maxSuffix =
              maximumLength
              |> Maybe.map (\n -> ".max(" ++ (toString n) ++ ")")
              |> Maybe.withDefault ""
          in
          "Joi.string()" ++ emailSuffix ++ maxSuffix
        Number { real, allowNegative } ->
          "Joi.number()"
        Date { time } ->
          "Joi.date()"
    
    propertyName =
      underscored item.name

    requiredString =
      if item.optional then
        ".optional()"
      else
        ".required()"
    
    schemaString =
      [ nativeKind
      , requiredString
      ]
      |> String.join ""

    field =
      (propertyName, schemaString)
    
    priority : Int
    priority =
      if item.isPrimaryKey then
        2
      else
        1
  in
    ( priority, field ) :: list

{-| Generates JavaScript code creating a Joi schema -}
createSchemaCode : Schema -> String
createSchemaCode schema =
  let
    constantName =
      schema.individualName
      |> lowerCamelize

    fields =
      List.foldr createSchemaCodeFold [] schema.items
      |> List.sortBy Tuple.first
      |> List.map Tuple.second
      |> pairsToJSObject True
  in
    "const " ++ constantName ++ " = " ++
    "Joi.object(" ++ fields ++ ");"
