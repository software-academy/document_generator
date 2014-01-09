require 'spec_helper'

describe DocumentGenerator::DiffFile do
  let(:diff_file) { described_class.new(git_diff_file) }
  let(:git_diff_file) { double(type: type, patch: patch, path: file_name) }

  context 'when the git diff represents a new file' do
    let(:type) { 'new' }
    let(:file_name) { '/spec/support/capybara.rb' }

    let(:patch) do
<<-PATCH
diff --git a/spec/support/capybara.rb b/spec/support/capybara.rb
new file mode 100644
index 0000000..12cefac
--- /dev/null
+++ b/spec/support/capybara.rb
@@ -0,0 +1 @@
+Capybara.javascript_driver = :webkit
\ No newline at end of file
PATCH
    end

    let(:ending) do
<<-EXPECTED
 Capybara.javascript_driver = :webkit
EXPECTED
    end

    let(:expected_content) do
<<-EXPECTED_CONTENT
###Create file `/spec/support/capybara.rb`

####Add
```
 Capybara.javascript_driver = :webkit
```


EXPECTED_CONTENT
    end

    describe '#patch_heading' do
      it 'has correct type and path' do
        expect(diff_file.patch_heading).to eq "Create file `#{file_name}`"
      end
    end

    describe '#content' do
      it 'contains the expected content' do
        expect(diff_file.content).to eq expected_content
      end
    end

    describe '#ending_code' do
      it 'contains the ending_code' do
        expect(diff_file.ending_code).to eq ending.rstrip
      end
    end

    describe '#action_type' do
      it 'outputs correct phrase for action_type' do
        expect(diff_file.action_type).to eq "Create file"
      end
    end

    describe '#markdown_outputs' do
      it 'has correct markdown outputs' do
        expect(diff_file.markdown_outputs.first.description).to eq "Add"
        expect(diff_file.markdown_outputs.first.escaped_content).to eq " Capybara.javascript_driver = :webkit"
      end
    end
  end

  context 'when the git diff represents a changed file' do
    let(:type) { 'modified' }
    let(:file_name) { '/app/views/posts/new.html.erb' }

    let(:patch) do
<<-PATCH
diff --git a/app/views/posts/new.html.erb b/app/views/posts/new.html.erb
index 58053b0..ca57827 100644
--- a/app/views/posts/new.html.erb
+++ b/app/views/posts/new.html.erb
@@ -1,13 +1,13 @@
<h1>New Post</h1>

-<%= form_for :post do |f| %>
+<%= form_for :post, url: posts_path do |f| %>
 <p>
   <%= f.label :title %><br>
   <%= f.text_field :title %>
 </p>

 <p>
   <%= f.label :text %><br>
   <%= f.text_area :text %>
 </p>
PATCH
    end

    let(:ending) do
<<-EXPECTED
<h1>New Post</h1>

 <%= form_for :post, url: posts_path do |f| %>
 <p>
   <%= f.label :title %><br>
   <%= f.text_field :title %>
 </p>

 <p>
   <%= f.label :text %><br>
   <%= f.text_area :text %>
 </p>
EXPECTED
    end

    let(:expected_content) do
<<-EXPECTED_CONTENT
Update file `/app/views/posts/new.html.erb`

Change
 <%= form_for :post do |f| %>


To
 <%= form_for :post, url: posts_path do |f| %>


Becomes
 <h1>New Post</h1>

 <%= form_for :post, url: posts_path do |f| %>
 <p>
   <%= f.label :title %><br>
   <%= f.text_field :title %>
 </p>

 <p>
   <%= f.label :text %><br>
   <%= f.text_area :text %>
 </p>


EXPECTED_CONTENT
    end


    describe '#patch_heading' do
      it 'has correct type and path' do
        expect(diff_file.patch_heading).to eq "Update file `#{file_name}`"
      end
    end

    describe '#ending_code' do
      it 'contains the ending_code' do
        expect(diff_file.ending_code).to eq ending.strip
      end
    end

    describe '#action_type' do
      it 'outputs correct phrase for action_type' do
        expect(diff_file.action_type).to eq "Update file"
      end
    end

    describe '#markdown_outputs' do
      it 'has correct markdown outputs' do
        expect(diff_file.markdown_outputs.first.description).to eq "Change"
        expect(diff_file.markdown_outputs.first.escaped_content).to eq " <%= form_for :post do |f| %>"

        expect(diff_file.markdown_outputs[1].description).to eq "To"
        expect(diff_file.markdown_outputs[1].escaped_content).to eq " <%= form_for :post, url: posts_path do |f| %>"

        expect(diff_file.markdown_outputs[2].description).to eq "Becomes"
        expect(diff_file.markdown_outputs[2].escaped_content).to eq diff_file.ending_code
      end
    end

    describe '#patch_heading' do
      let(:patch) { double(path: 'foo') }
      it 'has correct type and path' do
        expect(diff_file.patch_heading).to eq "Update file `#{file_name}`"
      end
    end
  end

  context 'when the git diff file has two changes in different hunks' do
    let(:type) { 'modified' }
    let(:file_name) { '/spec/controllers/posts_controller_spec.rb' }

    let(:patch) do
<<-PATCH
stuffasdfasdfadasdfasd
asdadsfasdfasdf
asdfasdfasdfasdf
@@ -5,7 +5,7 @@
   describe 'GET #new' do
     it "returns http success" do
       get :new
-      response.should be_success
+      expect(response).to be_success
     end
   end

@@ -19,7 +19,7 @@
   describe 'GET #index' do
     it "returns http success" do
       get :index
-      response.should be_success
+      expect(response).to be_success
     end
   end
 end
PATCH
    end

    let(:ending) do
<<-ENDING
   describe 'GET #new' do
     it "returns http success" do
       get :new
       expect(response).to be_success
     end
   end
   describe 'GET #index' do
     it "returns http success" do
       get :index
       expect(response).to be_success
     end
   end
 end
ENDING
    end

    let(:expected_content) do
<<-EXPECTED_CONTENT
###Update file `/spec/controllers/posts_controller_spec.rb`

####Change
```
       response.should be_success
```


####To
```
       expect(response).to be_success
```


####Becomes
```
   describe 'GET #new' do
     it "returns http success" do
       get :new
       expect(response).to be_success
     end
   end

```


####Change
```
       response.should be_success
```


####To
```
       expect(response).to be_success
```


####Becomes
```
   describe 'GET #index' do
     it "returns http success" do
       get :index
       expect(response).to be_success
     end
   end
 end

```


EXPECTED_CONTENT
    end

    describe '#content' do
      it 'includes the Becomes section' do
        expect(diff_file.content).to eq expected_content
      end
    end

    describe '#ending_code' do
      it 'contains the ending_code' do
        expect(diff_file.ending_code).to eq ending.rstrip
      end
    end

    describe '#action_type' do
      it 'outputs correct phrase for action_type' do
        expect(diff_file.action_type).to eq "Update file"
      end
    end

    describe '#markdown_outputs' do
      it 'has correct markdown outputs' do
        expect(diff_file.markdown_outputs.first.description).to eq "Change"
        expect(diff_file.markdown_outputs.first.content).to eq ["       response.should be_success"]

        expect(diff_file.markdown_outputs[1].description).to eq "To"
        expect(diff_file.markdown_outputs[1].content).to eq ["       expect(response).to be_success"]

        expect(diff_file.markdown_outputs[2].description).to eq "Becomes"
        expect(diff_file.markdown_outputs[2].content).to eq ["   describe 'GET #new' do", "     it \"returns http success\" do", "       get :new", "       expect(response).to be_success", "     end", "   end"]

        expect(diff_file.markdown_outputs[3].description).to eq "Change"
        expect(diff_file.markdown_outputs[3].content).to eq ["       response.should be_success"]

        expect(diff_file.markdown_outputs[4].description).to eq "To"
        expect(diff_file.markdown_outputs[4].content).to eq ["       expect(response).to be_success"]

        expect(diff_file.markdown_outputs[5].description).to eq "Becomes"
        expect(diff_file.markdown_outputs[5].content).to eq ["   describe 'GET #index' do", "     it \"returns http success\" do", "       get :index", "       expect(response).to be_success", "     end", "   end", " end"]
      end
    end
  end

  context 'when the git diff file has two changes' do
    let(:type) { 'modified' }
    let(:file_name) { '/spec/controllers/posts_controller_spec.rb' }

    let(:patch) do
<<-PATCH
diff --git a/spec/controllers/posts_controller_spec.rb b/spec/controllers/posts_controller_spec.rb
index f531cdc..1982a3e 100644
--- a/spec/controllers/posts_controller_spec.rb
+++ b/spec/controllers/posts_controller_spec.rb
@@ -2,9 +2,9 @@ require 'spec_helper'
describe PostsController do

-  describe GET new do
+  describe GET new do
   it returns http success do
-      get new
+      get new
     response.should be_success
   end
 end
PATCH
    end

    let(:ending) do
<<-ENDING
describe PostsController do

   describe GET new do
   it returns http success do
       get new
     response.should be_success
   end
 end
ENDING
    end

    let(:expected_content) do
<<-EXPECTED_CONTENT
###Update file `/spec/controllers/posts_controller_spec.rb`

####Change
```
   describe GET new do
```


####To
```
   describe GET new do
```


####Change
```
       get new
```


####To
```
       get new
```


####Becomes
```
describe PostsController do

   describe GET new do
   it returns http success do
       get new
     response.should be_success
   end
 end

```


EXPECTED_CONTENT
    end

    describe '#content' do
      it 'includes the Becomes section' do
        expect(diff_file.content).to eq expected_content
      end
    end

    describe '#ending_code' do
      it 'contains the ending_code' do
        expect(diff_file.ending_code).to eq ending.strip
      end
    end

    describe '#action_type' do
      it 'outputs correct phrase for action_type' do
        expect(diff_file.action_type).to eq "Update file"
      end
    end

    describe '#markdown_outputs' do
      it 'has correct markdown outputs' do
        expect(diff_file.markdown_outputs.first.description).to eq "Change"
        expect(diff_file.markdown_outputs.first.content).to eq ["   describe GET new do"]

        expect(diff_file.markdown_outputs[1].description).to eq "To"
        expect(diff_file.markdown_outputs[1].content).to eq ["   describe GET new do"]

        expect(diff_file.markdown_outputs[2].description).to eq "Change"
        expect(diff_file.markdown_outputs[2].content).to eq ["       get new"]

        expect(diff_file.markdown_outputs[3].description).to eq "To"
        expect(diff_file.markdown_outputs[3].content).to eq ["       get new"]

        expect(diff_file.markdown_outputs[4].description).to eq "Becomes"
        expect(diff_file.markdown_outputs[4].content).to eq ["describe PostsController do", "", "   describe GET new do", "   it returns http success do", "       get new", "     response.should be_success", "   end", " end"]
      end
    end
  end

  context 'when the git diff file has just a remove' do
    let(:type) { 'modified' }
    let(:file_name) { '/config/routes.rb' }

    let(:patch) do
<<-PATCH
diff --git a/config/routes.rb b/config/routes.rb
index d81896f..9595f17 100644
--- a/config/routes.rb
+++ b/config/routes.rb
@@ -1,10 +1,9 @@
Blog::Application.routes.draw do
-  get "welcome/index"
   # The priority is based upon order of creation: first created -> highest priority.
   # See how all your routes lay out with "rake routes".
PATCH
    end

    let(:ending) do
<<-EXPECTED
Blog::Application.routes.draw do
   # The priority is based upon order of creation: first created -> highest priority.
   # See how all your routes lay out with "rake routes".
EXPECTED
    end

    describe '#ending_code' do
      it 'contains the ending_code' do
        expect(diff_file.ending_code).to eq ending.strip
      end
    end

    describe '#action_type' do
      it 'outputs correct phrase for action_type' do
        expect(diff_file.action_type).to eq "Update file"
      end
    end

    describe '#markdown_outputs' do
      it 'has correct markdown outputs' do
        expect(diff_file.markdown_outputs.first.description).to eq "Remove"
        expect(diff_file.markdown_outputs.first.content).to eq ["   get \"welcome/index\""]
      end
    end
  end

  context 'when the patch contains one line' do
    let(:type) { 'new' }
    let(:file_name) { '/spec/support/capybara.rb' }

    let(:patch) do
<<-PATCH
diff --git a/spec/support/capybara.rb b/spec/support/capybara.rb
new file mode 100644
index 0000000..12cefac
--- /dev/null
+++ b/spec/support/capybara.rb
@@ -0,0 +1 @@
+Capybara.javascript_driver = :webkit
PATCH
    end

    let(:expected_content) do
<<-EXPECTED_CONTENT
###Create file `/spec/support/capybara.rb`

####Add
```
 Capybara.javascript_driver = :webkit
```


EXPECTED_CONTENT
    end

    describe '#content' do
      it 'does not contain Becomes content' do
        expect(diff_file.content).to eq expected_content
      end
    end
  end

  context 'when the patch contains multiple new lines' do
    let(:type) { 'new' }
    let(:file_name) { '/spec/support/capybara.rb' }

    let(:patch) do
<<-PATCH
diff --git a/spec/support/capybara.rb b/spec/support/capybara.rb
new file mode 100644
index 0000000..12cefac
--- /dev/null
+++ b/spec/support/capybara.rb
@@ -0,0 +1 @@
+this
+that
+other
PATCH
    end

    describe '#markdown_outputs' do
      it 'has correct markdown outputs' do
        expect(diff_file.markdown_outputs.size).to eq 1
      end
    end
  end

  context 'when the patch type is deleted' do
    let(:type) { 'deleted' }
    let(:file_name) { '/app/helpers/welcome_helper.rb' }

    let(:patch) do
<<-PATCH
diff --git a/app/helpers/welcome_helper.rb b/app/helpers/welcome_helper.rb
deleted file mode 100644
index eeead45..0000000
--- a/app/helpers/welcome_helper.rb
+++ /dev/null
@@ -1,2 +0,0 @@
-module WelcomeHelper
-end
PATCH
    end

    let(:expected_content) do
<<-EXPECTED_CONTENT
###Remove file `/app/helpers/welcome_helper.rb`

EXPECTED_CONTENT
    end

    describe '#content' do
      it 'has correct markdown outputs' do
        expect(diff_file.content).to eq expected_content
      end
    end
  end
end
