require 'bundler/setup'
Bundler.require(:default)
Dotenv.load

class App < Sinatra::Base
  set :root, File.dirname(__FILE__)

  configure :development do
    register Sinatra::Reloader
  end

  configure do
    register Sinatra::Namespace
    set :publishable_key, ENV['STRIPE_PUBLISHABLE_KEY'],
        :secret_key, ENV['STRIPE_SECRET_KEY'],
        :contentful_space, ENV['CONTENTFUL_SPACE'],
        :contentful_token, ENV['CONTENTFUL_TOKEN'],
        :javascripts, :jquery
    Stripe.api_key = settings.secret_key
  end

  error Stripe::CardError do
    env['sinatra.error'].message
  end

  # HOME PAGE #######################################
  get '/' do
    set_meta

    @posts = get_entries("post", "-fields.date")
    @products = get_entries("product", "sys.createdAt")

    haml :index
  end

  # BLOG ############################################
  namespace '/articles' do
    get do
      set_meta('Articles')
      @posts = get_entries("post", "-fields.date")
      haml :"articles/index"
    end
    get '/:id' do
      post = get_entry_raw(params[:id])
      set_meta(post.title)
      haml :"articles/show",
      locals: {
        post: get_entry(params[:id])
      }
    end
  end

  # STORE ############################################
  namespace '/shop' do
    get do
      set_meta('Shop')
      @products = get_entries("product", "sys.createdAt")
      haml :"shop/index"
    end
    get '/:id' do
      product = get_entry_raw(params[:id])
      set_meta(product.product_name)
      js :main
      haml :"shop/show",
      locals: {
        product: get_entry(params[:id])
      }
    end
    post '/charge/:id' do

      @product = get_entry(params[:id])

      @product.each do |product|
        @amount = product.price * 100
        @name = product.product_name
      end

      customer = Stripe::Customer.create(
        :email => params[:stripeEmail],
        :source  => params[:stripeToken]
      )

      charge = Stripe::Charge.create(
        :amount      => @amount,
        :description => @name,
        :currency    => 'usd',
        :customer    => customer.id
      )

      haml :"shop/charge"
    end
  end

  def get_entries content, order, limit=nil, includes=2
    contentful(
      settings.contentful_space,
      settings.contentful_token
    ).entries(
      content_type: content,
      order: order,
      limit: limit,
      include: includes
    )
  end

  def get_entry id
    contentful(
    settings.contentful_space,
    settings.contentful_token
    ).entries(
      'sys.id' => id
    )
  end

  def get_entry_raw id
    contentful(
    settings.contentful_space,
    settings.contentful_token
    ).entry(id)
  end

  def set_meta(title=nil, desc=nil)
    meta = get_entry_raw('7ivlJ7ocowus8wmMUaMSA0')
    if !title
      @title = meta.site_title + ' - ' + meta.site_name
    else
      @title = title + ' - ' + meta.site_name
    end
    if !title
      @desc = meta.site_description
    else
      @desc = desc
    end
  end

  private

  def contentful(space, token)
    @client ||= Contentful::Client.new(
      space: space,
      access_token: token,
      dynamic_entries: :auto,
      raise_errors: true
    )
  end

  # HELPERS ########################################
  helpers do
    def truncate string, max
      string.length > max ? "#{string[0...max]}..." : string
    end

    def published_at date
      @mo = date.strftime('%b')
      @day = date.strftime('%d')
      @yr = date.strftime('%Y')
      return "Published on #{@mo} #{@day}, #{@yr}"
    end

    def meta
      html="<meta charset=\"utf-8\" /><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, minimum-scale=1.0\"/>"
      html << "<meta name=\"description\"content=\"#{@desc}\"  />" if @desc
    end

    def favicon
      "<link href=\"/favicon.ico\" rel=\"shortcut icon\" />"
    end

    def ie_shim
      "<!--[if lt IE 9]><script src=\"http://html5shiv.googlecode.com/svn/trunk/html5.js\"></script><![endif]-->"
    end

    def title value=nil
      @title = value || settings.title || "untitled"
    end

    def title_tag
      "<title>#{@title}</title>"
    end

    def path_to script
      case script
        when :jquery then 'https://cdnjs.cloudflare.com/ajax/libs/jquery/2.2.4/jquery.min.js'
        #moo, prototype, scriptaculous, jquery ui, yui, dojo, raphael, extjs
        else "/javascripts/#{script}.js"
      end
    end

    def javascripts(*args)
      js = []
      js << settings.javascripts if settings.respond_to?('javascripts')
      js << args
      js << @js if @js
      js.flatten.uniq.map do |script|
        "<script src=\"#{path_to script}\"></script>"
      end.join
    end

    def js(*args)
      @js ||= []
      @js = args
    end

    def styles(*args)
        css = []
        css << settings.css if settings.respond_to?('css')
        css << args
        css << @css if @css
        css.flatten.uniq.map do |stylesheet|
          "<link href=\"/#{stylesheet}.css\" media=\"screen, projection\" rel=\"stylesheet\" />"
        end.join
    end

    def css(*args)
      @css ||= []
      @css += args
    end

    def webfonts(*args)
      "<link href=\"http://fonts.googleapis.com/css?family=#{((@fonts?settings.fonts+@fonts:settings.fonts)+args).uniq.*'|'}\" rel=\"stylesheet\" />"
    end
  end

end
