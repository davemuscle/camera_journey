
% Inputs:
%  features(NumImages,NumFeatures,8)
%  

weak_classifiers = zeros(NumImages,NumFeatures,4);

for feature_idx = 1:NumFeatures
    % Load the feature data into a workable array
    wc_feature = zeros(NumImages,3);
    for n = 1:NumImages
        wc_feature(n,:) = reshape(features(n,feature_idx,6:8),1,3);
    end
    
    % The wc_feature array now is (NumImages,3)
    % [1] - Feature value
    % [2] - Image Label
    % [3] - Image Number
    wc_feature_sorted = [wc_feature,zeros(NumImages,1)];
    [wc_feature_sorted(:,1),sortIdx] = sort(wc_feature(:,1));
    wc_feature_sorted(:,2) = wc_feature_sorted(sortIdx,2);
    wc_feature_sorted(:,3) = wc_feature_sorted(sortIdx,3);
    wc_feature_sorted(:,4) = weights(sortIdx)';
    
    pos_cnt = 0;
    neg_cnt = 0;
    
    pos_weight_sum = 0;
    neg_weight_sum = 0;
    
    best_threshold = 0;
    best_polarity = 0;
    min_error = (2^32)-1;
    
    for n = 1:NumImages
       
        error = min(neg_weight_sum + pos_cnt - pos_weight_sum, ...
                    pos_weight_sum + neg_cnt - neg_weight_sum);
                
        if(error < min_error)
            best_feature_idx = feature_idx;
            best_threshold = wc_feature_sorted(n,1);
            if(pos_cnt > neg_cnt) 
                polarity = 1;
            else
                polarity = -1;
            end
        end
                
        if(wc_feature_sorted(n,2) == 1)
            pos_cnt = pos_cnt + 1;
            pos_weight_sum = wc_feature_sorted(n,4) + pos_weight_sum;
        else
            neg_cnt = neg_cnt + 1;
            neg_weight_sum = wc_feature_sorted(n,4) + neg_weight_sum;  
        end
        
        % Weak Classifier
        if(best_polarity*wc_feature_sorted(n,1) < best_polarity*best_threshold)
            h = 1;
        else
            h = 0;
        end
            
        weak_classifiers(n,feature_idx,1) = h;
        weak_classifiers(n,feature_idx,2) = error;
        weak_classifiers(n,feature_idx,3) = feature_idx;
        weak_classifiers(n,feature_idx,4) = wc_feature_sorted(n,4);
        
    end
    
    
    
end