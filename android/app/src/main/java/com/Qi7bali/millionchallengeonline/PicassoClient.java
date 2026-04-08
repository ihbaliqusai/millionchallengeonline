package com.Qi7bali.millionchallengeonline;

import android.content.Context;
import android.widget.ImageView;

import com.squareup.picasso.Callback;
import com.squareup.picasso.MemoryPolicy;
import com.squareup.picasso.NetworkPolicy;
import com.squareup.picasso.Picasso;

public class PicassoClient {

    public static void downloadImage(final Context c, final String imageUrl, final ImageView img, final boolean cacheIt)
    {
        if(imageUrl.length()>0 && imageUrl!=null)
        {
            // load image from cache
            Picasso
                    .with(c)
                    .load(imageUrl)
                    .networkPolicy(NetworkPolicy.OFFLINE)
                    .noFade()
                    .fit()
                    .centerInside()
                    .into(img, new Callback()
                    {
                        @Override
                        public void onSuccess() {
                            //Log.d("Picasso", "Image loaded from cache>>>" + urlImageQuestion);
                        }

                        @Override
                        public void onError() {
                            //If we have to cache image Off line
                             if(cacheIt ){
                                 //cashe image
                                 Picasso
                                        .with(c)
                                        .load(imageUrl)
                                        .fetch();

                                 //load from cache
                                 Picasso
                                         .with(c)
                                         .load(imageUrl)
                                         .networkPolicy(NetworkPolicy.OFFLINE)
                                         .into(img, new Callback()
                                         {
                                             @Override
                                             public void onSuccess() {
                                                 //Log.d("Picasso", "Image loaded from cache>>>" + urlImageQuestion);
                                             }

                                             @Override
                                             public void onError() {
                                                 Picasso
                                                         .with(c)
                                                         .load(imageUrl)
                                                         .into(img);
                                             }
                                         });
                             } else {
                                 Picasso
                                         .with(c)
                                         .load(imageUrl)
                                         .into(img);

                             }
                        }
                    });
        } else {
            Picasso.with(c).load(R.drawable.empty).into(img);
        }
    }
}