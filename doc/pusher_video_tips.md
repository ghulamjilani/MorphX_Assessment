##### How to make portal work locally with video?

start portal application on port 3000,
start api application on port 3001,
(both have to share connection to same database)

create/join session, join as organizer and video has to appear.

#### как локально сымитировать начало лайвстрим сессии?(не через видеоклиент)
открыть страницу сессии с лайвстримом и выполнить в консоли браузера

    show_video_frame('/fuu/bar', {})

##### как сымитировать окончание сессии не дожидаясь ее завершения?

Max Dolgih: можешь отсылатиь запрос через пушер сайт
или через консоль в апи

https://github.com/alexwilner/LCMS_API/blob/develop/lib/sender/portal/interactive.rb#L45

Api rails c: Sender::Portal::Interactive.session_ended(room)

или через консоль в пушере - see doc/pusher_admin_interface_session_ended.png

##### how to imitate that video has started even without starting a camera?

Google Chrome, as session organizer, on "Loading.." step of video client
execute the following code:

    app.uiInCallShowApp(true, false)

and you will see that left/top/right sidebars are displayed and "Loading." step is skipped.

##### how to imitate that livestream has started?

    uiInCallShow(true, false)

