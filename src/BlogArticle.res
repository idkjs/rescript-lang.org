/*
      This module is responsible for statically prerendering each individual blog post.
 General concepts:
      -----------------------
      - We use webpack's "require" mechanic to reuse the MDX pipeline for rendering
      - Frontmatter is being parsed and attached as an attribute to the resulting component function via plugins/mdx-loader
      - We generate a list of static paths for each blog post via the BlogApi module (using fs)
      - The contents of this file is being reexported by /pages/blog/[slug].js


      A Note on Performance:
      -----------------------
      Luckily, since pages are prerendered, we don't need to worry about
      increased bundle sizes due to the `require` with path interpolation. It
      might cause longer builds though, so we might need to refactor as soon as
      builds are taking too long.  I think we will be fine for now.
  Link to NextJS discussion: https://github.com/zeit/next.js/discussions/11728#discussioncomment-3501
 */
let middleDotSpacer = " " ++ (Js.String.fromCharCode(183) ++ " ")

module Params = {
  type t = {slug: string}
}

type props = {fullslug: string}

module BlogComponent = {
  type t = {default: React.component<{.}>}

  @val external require: string => t = "require"

  let frontmatter: React.component<{.}> => Js.Json.t = %raw(`
      function(component) {
        if(typeof component.frontmatter === "object") { return component.frontmatter; }
        return {};
      }
    `)
}

module Line = {
  @react.component
  let make = () => <div className="block border-t border-gray-20" />
}

module AuthorBox = {
  @react.component
  let make = (~author: BlogFrontmatter.author) => {
    let authorImg = <img className="h-full w-full rounded-full" src=author.imgUrl />

    <div className="flex items-center">
      <div className="w-12 h-12 bg-berry-40 block rounded-full mr-3"> authorImg </div>
      <div className="text-14 font-medium text-gray-95">
        <a
          href={"https://twitter.com/" ++ author.twitter}
          className="hover:text-gray-80"
          rel="noopener noreferrer"
          target="_blank">
          {React.string(author.fullname)}
        </a>
        <div className="text-gray-60"> {React.string(author.role)} </div>
      </div>
    </div>
  }
}

module BlogHeader = {
  @react.component
  let make = (
    ~date: DateStr.t,
    ~author: BlogFrontmatter.author,
    ~co_authors: array<BlogFrontmatter.author>,
    ~title: string,
    ~category: option<string>=?,
    ~description: option<string>,
    ~articleImg: option<string>,
  ) => {
    let date = DateStr.toDate(date)

    let authors = Belt.Array.concat([author], co_authors)

    <div className="flex flex-col items-center">
      <div className="w-full max-w-740">
        <div className="text-gray-60 text-lg mb-5">
          {switch category {
          | Some(category) => <> {React.string(category)} {React.string(middleDotSpacer)} </>
          | None => React.null
          }}
          {React.string(Util.Date.toDayMonthYear(date))}
        </div>
        <h1 className=Text.H1.default> {React.string(title)} </h1>
        {description->Belt.Option.mapWithDefault(React.null, desc =>
          switch desc {
          | "" => <div className="mb-8" />
          | desc =>
            <div className="my-8 text-gray-95">
              <Markdown.Intro> {React.string(desc)} </Markdown.Intro>
            </div>
          }
        )}
        <div className="flex flex-col md:flex-row mb-12">
          {Belt.Array.map(authors, author =>
            <div
              key=author.username
              style={ReactDOMStyle.make(~minWidth="8.1875rem", ())}
              className="mt-4 md:mt-0 md:ml-8 first:ml-0">
              <AuthorBox author />
            </div>
          )->React.array}
        </div>
      </div>
      {switch articleImg {
      | Some(articleImg) =>
        <div className="-mx-8 sm:mx-0 sm:w-full bg-gray-5-tr md:mt-24">
          <img
            className="h-full w-full object-cover"
            src=articleImg
            style={ReactDOMStyle.make(~maxHeight="33.625rem", ())}
          />
        </div>
      | None => <div className="max-w-740 w-full"> <Line /> </div>
      }}
    </div>
  }
}

let default = (props: props) => {
  let {fullslug} = props

  let module_ = BlogComponent.require("../_blogposts/" ++ (fullslug ++ ".mdx"))

  let archived = Js.String2.startsWith(fullslug, "archive/")

  let component = module_.default

  let fm = component->BlogComponent.frontmatter->BlogFrontmatter.decode(~authors=BlogFrontmatter.authors)

  let children = React.createElement(component, Js.Obj.empty())

  let archivedNote = archived
    ? {
        open Markdown
        <div className="mb-10">
          <Warn>
            <P>
              <span className="font-bold"> {React.string("Important: ")} </span>
              {React.string(
                "This is an archived blog post, kept for historical reasons. Please note that this information might be outdated.",
              )}
            </P>
          </Warn>
        </div>
      }
    : React.null

  let content = switch fm {
  | Ok({
      date,
      author,
      co_authors,
      title,
      description,
      canonical,
      articleImg,
      previewImg,
    }) =>
    <div className="w-full">
      <Meta
        title={title ++ " | ReScript Blog"}
        description=?{description->Js.Null.toOption}
        canonical=?{canonical->Js.Null.toOption}
        ogImage={previewImg->Js.Null.toOption->Belt.Option.getWithDefault(Blog.defaultPreviewImg)}
      />
      <div className="mb-10 md:mb-20">
        <BlogHeader
          date
          author
          co_authors
          title
          description={description->Js.Null.toOption}
          articleImg={articleImg->Js.Null.toOption}
        />
      </div>
      <div className="flex justify-center">
        <div className="max-w-740 w-full">
          archivedNote
          children
          {switch canonical->Js.Null.toOption {
          | Some(canonical) =>
            <div className="mt-12 text-14">
              {React.string("This article was originally released on ")}
              <a href=canonical target="_blank" rel="noopener noreferrer">
                {React.string(canonical)}
              </a>
            </div>
          | None => React.null
          }}
          <div className="mt-12">
            <Line />
            <div className="pt-20 flex flex-col items-center">
              <div className="text-3xl sm:text-32 text-center text-gray-95 font-medium">
                {React.string("Want to read more?")}
              </div>
              <Next.Link href="/blog">
                <a className="text-fire hover:text-fire-70">
                  {React.string("Back to Overview")}
                  <Icon.ArrowRight className="ml-2 inline-block" />
                </a>
              </Next.Link>
            </div>
          </div>
        </div>
      </div>
    </div>

  | Error(msg) =>
    <div>
      <Markdown.Warn>
        <h2 className="font-bold text-gray-95 text-28 mb-2">
          {React.string("Could not parse file '_blogposts/" ++ (fullslug ++ ".mdx'"))}
        </h2>
        <p>
          {React.string("The content of this blog post will be displayed as soon as all
            required frontmatter data has been added.")}
        </p>
        <p className="font-bold mt-4"> {React.string("Errors:")} </p>
        {React.string(msg)}
      </Markdown.Warn>
    </div>
  }
  <MainLayout> content </MainLayout>
}

let getStaticProps: Next.GetStaticProps.t<props, Params.t> = ctx => {
  open Next.GetStaticProps
  let {params} = ctx

  let fullslug = BlogApi.getFullSlug(params.slug)->Belt.Option.getWithDefault(params.slug)

  let props = {fullslug: fullslug}
  let ret = {"props": props}
  Promise.resolve(ret)
}

let getStaticPaths: Next.GetStaticPaths.t<Params.t> = () => {
  open Next.GetStaticPaths

  let paths = BlogApi.getAllPosts()->Belt.Array.map(postData => {
    params: {
      Params.slug: postData.slug,
    },
  })
  let ret = {paths: paths, fallback: false}
  Promise.resolve(ret)
}
