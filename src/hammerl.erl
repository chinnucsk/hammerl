-module(hammerl).

-include("blog.hrl").

%% API.
-export([start/0, dispatchers/0, reload_dispatchers/0, blog/1, bloglist/0]).

%% API.
start() ->
	ok = application:start(hammerl).

dispatchers() ->
	cowboy_router:compile([
		{'_', [
			{"/blog/[:blogname]", blog, []},
			{"/", index, []}
		]}
	]).

reload_dispatchers() ->
	cowboy:set_env(http, dispatch,
				   dispatchers()).

blog(Name) ->
	{_, _, _, Blog, _} = emysql:execute(blog_pool, blog_stmt_get, [Name]),
	case length(Blog) of
		0 ->
			{error, not_found};
		_N ->
			{ID, Date, URL, Title, Content} = list_to_tuple(lists:nth(1, Blog)),
			#blog{id = ID, date = Date, url = URL, title = Title, content = Content}
	end.

bloglist() ->
	{_, _, _, Blogs, _} = emysql:execute(blog_pool, <<"SELECT * FROM blog_entry">>),
	create_blog_list(Blogs).

create_blog_list([]) ->
	[];
create_blog_list(L) ->
	create_blog_list(L, []).
create_blog_list([], BlogEntries) ->
	BlogEntries;
create_blog_list([H|T], BlogEntries) ->
	{ID, Date, URL, Title, Content} = list_to_tuple(H),
	create_blog_list(T, [#blog{id = ID, date = Date, url = URL, title = Title, content = Content}|BlogEntries]).
