require 'spec_helper'

describe Cathode::Request do
  describe '.create' do
    subject do
      Cathode::Request.create(context_stub(
        headers: headers,
        params: ActionController::Parameters.new(params.merge(controller: 'products', action: action)),
        path: try(:path)
       ))
    end

    before do
      use_api do
        resource :products, actions: [:all] do
          attributes do
            params.require(:product).permit(:title)
          end
          get :custom do
            body Product.last
          end
        end
      end
    end

    context 'without a version header' do
      let(:action) { 'index' }
      let(:headers) { {} }
      let(:params) { {} }

      it 'sets status as bad request' do
        expect(subject._status).to eq(:bad_request)
      end

      it 'sets body text' do
        expect(subject._body).to eq('A version number must be passed in the Accept-Version header')
      end
    end

    context 'with an invalid version' do
      let(:action) { 'index' }
      let(:headers) { { 'HTTP_ACCEPT_VERSION' => '2.0.0' } }
      let(:params) { {} }

      it 'sets status as bad request' do
        expect(subject._status).to eq(:bad_request)
      end

      it 'sets body text' do
        expect(subject._body).to eq('Unknown API version: 2.0.0')
      end
    end

    context 'with a valid version' do
      let(:headers) { { 'HTTP_ACCEPT_VERSION' => '1.0.0' } }

      context 'with an invalid action' do
        let(:action) { 'invalid' }
        let(:params) { {} }

        it 'sets status as not found' do
          expect(subject._status).to eq(:not_found)
        end
      end

      context 'with a default action' do
        context ':index' do
          let(:action) { 'index' }
          let(:params) { {} }
          let!(:products) { create_list(:product, 5) }

          it 'sets status as ok' do
            expect(subject._status).to eq(:ok)
          end

          it 'sets body as all resource records' do
            expect(subject._body).to eq(Product.all)
          end

          context 'with paging' do
            before do
              params.merge! page: 2, per_page: 2
            end

            context 'when paging is not allowed' do
              it 'sets body as all records' do
                expect(subject._body).to eq(products)
              end

              it 'sets status as ok' do
                expect(subject._status).to eq(:ok)
              end
            end

            context 'when paging is allowed' do
              before do
                use_api do
                  resource :products do
                    action :index do
                      allows :paging
                    end
                  end
                end
              end

              it 'responds with the paged results' do
                expect(subject._body).to eq(products[2..3])
              end
            end
          end
        end

        context ':show' do
          let(:action) { 'show' }
          let(:params) { { id: 3 } }
          let!(:products) { create_list(:product, 3) }

          context 'without access filter' do
            it 'sets status as ok' do
              expect(subject._status).to eq(:ok)
            end

            it 'sets body as the resource' do
              expect(subject._body).to eq(products[2])
            end
          end
        end

        context ':create' do
          let(:action) { 'create' }

          context 'with valid attributes' do
            let(:params) { { product: { title: 'cool product' } } }

            it 'sets status as ok' do
              expect(subject._status).to eq(:ok)
            end

            it 'sets body as the new record' do
              expect(subject._body.title).to eq('cool product')
            end
          end

          context 'with invalid attributes' do
            let(:params) { { title: 'cool product' } }

            it 'sets status as bad request' do
              expect(subject._status).to eq(:bad_request)
            end

            it 'sets body as error message' do
              expect(subject._body).to eq('param is missing or the value is empty: product')
            end
          end
        end

        context ':update' do
          let(:action) { 'update' }
          let(:product) { create(:product, title: 'cool product') }

          context 'with valid attributes' do
            let(:params) { { id: product.id, product: { title: 'cooler product' } } }

            it 'sets status as ok' do
              expect(subject._status).to eq(:ok)
            end

            it 'sets body as the updated record' do
              expect(subject._body.title).to eq('cooler product')
            end
          end

          context 'with invalid attributes' do
            let(:params) { { id: product.id, title: 'cooler product' } }

            it 'sets status as bad request' do
              expect(subject._status).to eq(:bad_request)
            end

            it 'sets body as error message' do
              expect(subject._body).to eq('param is missing or the value is empty: product')
            end
          end
        end

        context ':destroy' do
          let(:action) { 'destroy' }
          let(:params) { { id: product.id } }
          let!(:product) { create(:product) }

          it 'sets status as ok' do
            expect(subject._status).to eq(:ok)
          end

          it 'sets body as empty' do
            expect(subject._body).to be_empty
          end

          it 'removes the record' do
            expect { subject }.to change { Product.count }.by(-1)
          end
        end
      end

      context 'with a custom action' do
        let(:action) { 'custom' }
        let!(:products) { create_list(:product, 3) }
        let(:params) { {} }
        let(:path) { 'products/custom'  }

        it 'sets status as ok' do
          expect(subject._status).to eq(:ok)
        end

        it 'sets body' do
          expect(subject._body).to eq(Product.last)
        end
      end
    end
  end
end
