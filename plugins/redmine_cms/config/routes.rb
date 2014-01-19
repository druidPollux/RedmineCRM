# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

match "/sitemap.xml" => "welcome#sitemap", :defaults => {:format => :xml}

match "projects/:project_id/pages/:tab" => "project_tabs#show", :as => "project_tab"

resources :cms_menus
resources :pages do
  member do
   get :expire_cache
  end
end
resources :parts
resources :pages_parts

match "pages/:project_id/:id" => "pages#show", :via => :get

match "pages/:page_id/add_part" => "pages_parts#add", :via => :post
match "pages/:page_id/delete_part/:part_id" => "pages_parts#delete", :via => :delete
match "pages/:page_id/update/:part_id" => "pages_parts#update", :via => :put

match 'attachments/thumbnail/:id(/:size)/:filename', :controller => 'attachments', :action => 'thumbnail', :id => /\d+/, :filename => /.*/, :via => :get, :size => /\d+/
