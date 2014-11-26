FORMAT: 1A

# Places Application Runtime API

NOTE: This document is a **work in progress**.


# Group Place

## Place [/core/api/v1/places/{id}]

This ressource represent one particular place identified by its *id*.

+ Model
    
    ```js
    {
      "id": "ansamb_0-lPcAY2W82PpCuuvram-w,ansamb_9NAG45-KUaOZaBV8ER8oww@ansamb_0-lPcAY2W82PpCuuvram-w",
      "name": "ansamb_0-lPcAY2W82PpCuuvram-w,ansamb_9NAG45-KUaOZaBV8ER8oww",
      "desc": "unique conversation place between ansamb_0-lPcAY2W82PpCuuvram-w and ansamb_9NAG45-KUaOZaBV8ER8oww",
      "type": "conversation",
      "owner_uid": null,
      "creation_date": "2014-09-03T08:12:45.000Z",
      "status": "validated",
      "network_synced": 2,
      "network_request_id": "b6eeefb2-be5f-4b11-985b-c93722134261",
      "add_request_id": null,
      "last_sync_date": null,
      "auto_sync": true,
      "auto_download": true,
      "created_at": "2014-09-03T08:12:45.000Z",
      "updated_at": "2014-09-03T08:12:50.000Z",
      "ansambers": [
        {
          "id": 3,
          "uid": "ansamb_9NAG45-KUaOZaBV8ER8oww",
          "place_id": "ansamb_0-lPcAY2W82PpCuuvram-w,ansamb_9NAG45-KUaOZaBV8ER8oww@ansamb_0-lPcAY2W82PpCuuvram-w",
          "admin": true,
          "status": "validated",
          "request_id": "0dee59cd-d2b0-4976-85b1-e705d03b41b3",
          "firstname": "ludovic",
          "lastname": "Maillot",
          "created_at": "2014-09-03T07:12:45.000Z",
          "updated_at": "2014-09-03T07:12:47.000Z"
        }
      ],
      "owner": null
    }
    ```

### Retrieve a place [GET]

+ Parameters
  
    + id (string, required) ... the place id

+ Response 200 (application/json)

    [Place][]


### Modify a place [PUT]

+ Parameters 
  + id (required, string)  ... the place id

+ Request (application/json)
{
  "name": "lesson 222",
  "desc":"All materials for lesson 13","id":"222"
}

+ Response 200 (application/json)
{
  "err": null,
  "data": {
    "creation_date": "2014-11-15T11:26:48.577Z",
    "status": "validated",
    "type": "share",
    "name": "lesson 222",
    "id": "222",
    "owner_uid": null,
    "desc": null,
    "network_synced": 0,
    "network_request_id": "cbce3520-0df0-475d-8919-913198c5bb2c",
    "add_request_id": null,
    "auto_sync": true,
    "auto_download": true,
    "updated_at": "2014-11-15T11:26:48.000Z",
    "created_at": "2014-11-15T11:26:48.000Z"
}




### Remove a place [DELETE]

+ Parameters
  + id (required, string) ... the place id

+ Response 200 (application/json)
{
  "err": null,
  "deleted": true
}


## Place Creation [/core/api/v1/places/]

### Create a new place [POST]

+ Request (application/json)
{
  "desc":"All materials for lesson 13",
  "type": "share",
  "name": "My place"
}

+ Response 200 (application/json)
{
  "err": null,
  "data": {
    "creation_date": "2014-11-16T04:38:36.730Z",
    "status": "validated",
    "type": "share",
    "name": "My place",
    "id": "e37e13d2-24f4-4ffa-b239-871cc5dd2423@ansamb_JYrcO1kWW6yUp9GAHE5GAg",
    "owner_uid": null,
    "desc": null,
    "network_synced": 0,
    "network_request_id": "9d803ce5-1ea7-4654-8311-bdad4b10ba75",
    "add_request_id": null,
    "auto_sync": true,
    "auto_download": true,
    "updated_at": "2014-11-16T04:38:36.000Z",
    "created_at": "2014-11-16T04:38:36.000Z"
    }
}


## Place Request [/core/api/v1/places/{id}/accept]

### Accept a place request [POST]

  + Parameters 
    + id (required, string)  ... the place id

  + Response 200 (application/json)


## Place Collection [/core/api/v1/places/]

### Retrieve all the places [GET]

+ Response 200 (application/json)
  {
      "err": null,
      "data": [
          {
              "id": "31d2f59d-5dcd-4a14-9bda-7a40e6c6f2f2@ansamb_SledmWD1XES7asq0JiobOA",
              "name": "photos",
              "desc": "",
              "type": "share",
              "owner_uid": null,
              "creation_date": "2014-11-18T10:31:51.000Z",
              "status": "validated",
              "network_synced": 2,
              "network_request_id": "e9e32f06-2e58-4567-afef-46830b612999",
              "add_request_id": null,
              "last_sync_date": null,
              "auto_sync": true,
              "auto_download": true,
              "created_at": "2014-11-18T10:31:51.000Z",
              "updated_at": "2014-11-18T10:31:52.000Z",
              "ansambers": [],
              "owner": null
          },
          {
              "id": "08b82e58-5b8f-4781-9e99-3014259a9a67@ansamb_SledmWD1XES7asq0JiobOA",
              "name": "videos",
              "desc": "",
              "type": "share",
              "owner_uid": null,
              "creation_date": "2014-11-18T10:31:54.000Z",
              "status": "validated",
              "network_synced": 0,
              "network_request_id": "f632c425-0e41-4c7b-9482-ba9d6ff050a6",
              "add_request_id": null,
              "last_sync_date": null,
              "auto_sync": true,
              "auto_download": true,
              "created_at": "2014-11-18T10:31:54.000Z",
              "updated_at": "2014-11-18T10:31:54.000Z",
              "ansambers": [],
              "owner": null
          }
      ]
  }

### Remove all the places [DELETE]

+ Response 200 (application/json)
  {
    "err": null,
    "data": 2
  }


# Group Ansamber 

An `ansamber` is the term used to designate a participant within a place. 


## Ansamber [/core/api/v1/places/{place_id}/ansambers/{ansamber}]

+ Parameters
    + place_id (string) ... the place id
    + ansamber (string) ... uid

+ Response 200 (application/json)


### Retrieve a particular ansamber [GET]
+ Response 200 (application/json)

## Add an ansamber to place [PUT]

+ Response 200 (application/json)
{
  "err": "Contact not found",
  "ok": false
}

### Remove an ansamber from a place [DELETE]
+ Response 200 (application/json)


## Ansamber Collection [/core/api/places/{place_id}/ansambers/]


### Retrieve all ansambers of a place [GET]

+ Parameters
  + place_id (string) ... id of the place


+ Response 200 (application/json)

{
  "err": null,
  "ansambers": []
}


# Group Contact 


## Lookup [/core/api/v1/contacts/aliases/lookup]

### Lookup [POST]

+ Parameters
  + type (string) ... type of the alias
  + alias (string) ... the alias

+ Request 200 (application/json)
{
  "type": "email",
  "alias": "didier@ansamb.com"
}

+ Response 200 (application/json)
  {
    "err": null,
    "contact": {
      "aliases": {
        "email/didier@ansamb.com": {
          "type": "email",
          "alias": "didier@ansamb.com"
        }
      },
      "uid": "ansamb_0-lPcAY2W82PpCuuvram-w",
      "firstname": "Didier",
      "lastname": "Hoareau"
    }
  }


## Contact [/core/api/v1/contacts/{uid}]

### Retrieve a particular contact [GET]

+ Parameters
    + uid (string) ... uid

+ Response 200 (application/json)
{
    "err": null,
    "data": [
        {
            "uid": "ansamb_PzVVQXehXgy8RllWEiIMpQ",
            "request_id": "ebf86b14-db85-4e9a-bda6-0768f032fbf1",
            "message": "",
            "firstname": "",
            "lastname": "",
            "password": "",
            "status": "validated",
            "created_at": "2014-11-18 10:48:57",
            "updated_at": "2014-11-18 10:50:17",
            "aliases": null,
            "conversation_id": "ansamb_PzVVQXehXgy8RllWEiIMpQ,ansamb_SledmWD1XES7asq0JiobOA@ansamb_PzVVQXehXgy8RllWEiIMpQ",
            "conversation_ready": true
        }
    ]
}


### Remove a contact [DELETE]
+ Response 200 (application/json)


## Contact Collection [/core/api/v1/contacts/]


### Retrieve all contacts [GET]

+ Parameters

  + status in [requested, pending, validated]

+ Response 200 (application/json)

  {
    "err": null,
    "data": [
      {...}, 
      {...}
      ]
  }

###  Add a contact [POST]

  + Request (application/json)
      {
        "type": "email",
        "alias": "fabrice.payet@ansamb.com"
      }  

  + Response 200 (application/json)

  {
      "err": null,
      "data": {
        "uid": "ansamb_5acbOJ3qWNOn1SiT8wZeZA",
        "aliases": [
          {
            "type": "email",
            "alias": "fabrice.payet@ansamb.com",
            "default_alias": true,
            "contact_uid": "ansamb_5acbOJ3qWNOn1SiT8wZeZA",
            "id": 4,
            "updated_at": "2014-11-20T11:58:16.000Z",
            "created_at": "2014-11-20T11:58:16.000Z"
          }
        ],
        "firstname": "Fabrice",
        "lastname": "Payet",
        "message": "Do you want to be my friend?",
        "status": "requested",
        "request_id": "bddc74e9-b2e1-44d7-8f6c-df54417333bd",
        "password": "",
        "updated_at": "2014-11-20T11:58:16.000Z",
        "created_at": "2014-11-20T11:58:16.000Z"
    }
  }

## Accept Reliationship [/core/api/v1/contacts/accept]

### Accept a contact request [POST]

  + Parameters
      + uid (string) ... user id

  + Request (application/json)
    {
      "uid": "ansamb_SledmWD1XES7asq0JiobOA"
    }
  
  + Response 200 (application/json)
    {
      "err": null,
      "ok": true
    }



## Reject Relationship [/core/api/v1/contacts/reject]

### Reject a contact request [POST]

  + Parameters
    + uid (string) ... user id

  + Request (application/json)
  {
    "uid": "ansamb_SledmWD1XES7asq0JiobOA"
  }


  + Response 200 (application/json)
  {
      "err": null
  }

## Defer Relationship [/core/api/v1/contacts/later]

### Defer a contact request [POST]

  + Parameters
      + uid (string) ... user id

  + Request (application/json)
    {
      "uid": "ansamb_SledmWD1XES7asq0JiobOA"
    }


  + Response 200 (application/json)
  {
      "err": null,
      "ok": true
  }



# Group Content 

## Content [/core/api/v1/places/{pid}/contents/{cid}]

### retrieve a specific content [GET]

+ Parameters

  + pid (string) ... the place id
  + cid (string) ... the content id

+ Response 200 (application/json)

{
    "err": null,
    "data": {
        "id": "4bb9844180b15da00d3ddee49ff36be95c2102ad67478b99ee08fec6dc20cfbc",
        "content_type": "file",
        "ref_content": null,
        "date": "2014-11-18T12:34:38.000Z",
        "synced": false,
        "downloadable": true,
        "downloaded": true,
        "uploaded": true,
        "uri": null,
        "status": null,
        "likes": 0,
        "owner": null,
        "read": true,
        "created_at": "2014-11-18T12:34:38.000Z",
        "updated_at": "2014-11-18T12:34:39.000Z",
        "data": {...}
    }
}

### delete a specific content [DELETE]

+ Parameters
  + pid (string) ... the place id
  + cid (string, required) ... the content id

+ Response 200 (application/json)
{
    "err": null,
    "deleted": true
}

## Content rename [/core/api/v1/places/{pid}/contents/{cid}/rename]

### rename a content [POST]

+ Parameters

  + pid (string) ... the place id
  + cid (string) ... the content id

+ Request (application/json)
  {
    "new_name": "My new name"
  }

+ Response 200

{
    "err": null,
    "data": {
        "id": "4bb9844180b15da00d3ddee49ff36be95c2102ad67478b99ee08fec6dc20cfbc",
        "content_type": "file",
        "ref_content": null,
        "date": "2014-11-18T12:34:38.000Z",
        "synced": false,
        "downloadable": true,
        "downloaded": true,
        "uploaded": true,
        "uri": null,
        "status": null,
        "likes": 0,
        "owner": null,
        "read": true,
        "created_at": "2014-11-18T12:34:38.000Z",
        "updated_at": "2014-11-18T12:34:39.000Z",
        "data": {...}
    }
}

## Content download [/core/api/v1/places/{pid}/contents/{cid}/download]

### download a content from the server [GET]

+ Parameters

  + pid (string) ... the place id
  + cid (string) ... the content id

+ Response 200

{
    "err": null
}

## Content copy [/core/api/v1/places/{pid}/contents/{cid}/copy]

### copy a content from a place to another [POST]

+ Parameters

  + pid (string, required) ... the place id
  + cid (string, required) ... the content id

+ Request (application/json)
  {
    "dpl": "{destination_place_id}"
  }

+ Response 200

{
    "err": null,
    "data": {
      "id": "60303ae22b998861bce3b28f33eec1be758a213c86c93c076dbe9f558c11c752",
      "owner": null,
      "content_type": "file",
      "date": "2014-11-19T13:43:13.183Z",
      "ref_content": null,
      "read": true,
      "downloadable": true,
      "downloaded": true,
      "uploaded": false,
      "synced": false,
      "uri": null,
      "status": null,
      "likes": 0,
      "updated_at": "2014-11-19T13:43:13.000Z",
      "created_at": "2014-11-19T13:43:13.000Z",
      "data": {
        "id": "60303ae22b998861bce3b28f33eec1be758a213c86c93c076dbe9f558c11c752",
        "name": "test2",
        "filesize": 7270,
        "mdate": "2014-04-17T07:26:04.000Z",
        "relative_path": "test2",
        "mime_type": "",
        "path": "",
        "extra": "",
        "updated_at": "2014-11-19T13:43:13.000Z",
        "created_at": "2014-11-19T13:43:13.000Z"
      }
    }
}

## Content path [/core/api/v1/places/{pid}/contents/{cid}/info/path]

### get the local absolute path of the file content [GET]

+ Parameters

  + pid (string) ... the place id
  + cid (string) ... the content id

+ Response 200

{
    "err": null,
    "path":"path/to/my/file"
}

## Content user copy [/core/api/v1/places/{pid}/contents/{cid}/user_download]

### copy the content into the provided path [POST]

+ Parameters

  + pid (string) ... the place id
  + cid (string) ... the content id

+ Request (application/json)
  {
    "download_path": "local/destination/folder"
  }

+ Response 200

{
    "err": null,
    "ok":true
}

## Content Collection [/core/api/places/{place_id}/contents/]


### Retrieve all contents of a place [GET]

+ Parameters
  + place_id (required, string) ... the place id


+ Response 200

{
    "err": null,
    "data": [
        { ... },
        { ... },
        { ... }
    ]
}

# Group Account

## Account [/core/api/v1/account]

### retrieve account document [GET]

+ Response 200 (application/json)
  {
    "err": null,
    "data": {
      "uid": "ansamb_JYrcO1kWW6yUp9GAHE5GAg",
      "aliases": {
        "email/didier+pk09@ansamb.com": {
          "alias": "didier+pk09@ansamb.com",
          "type": "email"
        }
      },
      "firstname": "d",
      "lastname": "h",
      "status": "validated"
    }
  }

# Group Applications API

Each applications is able to define some routes to handle settings, contents, .... HTTP method used for each routes is defined by the application itself. The most important thing to keep in mind is that a route can be called with two different modes: `in-place` or `standalone`.

In the `in-place` mode, the route handler will received a context object with a API restricted to the specified place. This mode is intended for routes which need to interact with the framework to make modifications onto a place.

In the `standalone` mode, no context will be provided so the route handler can't use Places' framework. This mode is intended for routes which are not related to any user place (application settings ...)

## standalone routing pattern [/application/api/v1/router/{app_name}/{app_route}]

+ Parameters
  + app_name (required, string) ... application name
  + app_route (required, string) ... application route (ex: settings/user/)

### HTTP method can be anything else [GET]

+ Response 200
  Application reply. Could be a json object, a binary reply, ...

## in-place routing pattern [/application/api/v1/router/{app_name}/places/{place_id}/{app_route}]

+ Parameters
  + app_name (required, string) ... application name
  + place_id (required, string) ... place id
  + app_route (required, string) ... application route (ex: settings/user/)

### HTTP method can be anything else [GET]

+ Response 200
  Application reply. Could be a json object, a binary reply, ...

## Places content [/application/api/v1/router/{app_name}/places/{place_id}/files/{file_name}]

This route is available for any application managing file content and allow to get the file content.

### Get a content [GET]

+ Parameters
  + app_name (required, string) ... application name
  + place_id (required, string) ... place_id
  + file_name (required, string) ... file name encoded correctly to be safely used into an URI (encodeURIComponent)

+ Response 200
  File content

+ Response 404
  Content not found within the place

## Static files [/application/static/{app_name}/{app_static_url}]

Static urls can be used by any application to serve assets like css/html/js files or whatever they need to.

+ Parameters
  + app_name (required, string) ... application name
  + app_static_url (required, string) ... application static url (ex: /public)

### Get a file served by the application [GET]

+ Response 200
  File content

+ Response 404

# Group Ansamb File

Ansamb_file is a Places' application responsible for handling file content (content-type=file). This application provide its own API to put/update a file within a place.

## File [/application/api/v1/router/ansamb_file/places/{place_id}/]

### Add a file to a place [POST]

+ Request (application/json)
  {
    "path":"local/path/to/file.pdf"
    "name":"file"
    "size":40000
    "type":"application/pdf"
    "lastModifiedDate":1416921878170
  }

+ Response 200 (application/json)
  {
    "err":null
    "data":{...}
  }

### Update a file [PUT]

+ Request (application/json)
  {
    "path":"local/path/to/file.pdf"
    "name":"file"
    "size":40000
    "type":"application/pdf"
    "lastModifiedDate":1416921878170
  }

+ Response 200 (application/json)
  {
    "err":null
    "data":{...}
  }

# Group Ansamb Post

Ansamb_post is a Places' application responsible for handling messages (content-type=post). This application provide its own API to create a post within a place.
Note that only conversation place use this content type. For now, post created into a `share` place are not displayed.

## Post [/application/api/v1/router/ansamb_post/places/{place_id}/]

+ Parameters
  + place_id (required, string) ... place id

### Create a message [POST]

+ Request (application/json)
  {
    "post":"my super post"
  }

+ Response 200
  {
    "err":null
    "data":{...}
  }

