 import React, { Component } from 'react';
 import './ContentRating.css';

 class ContentRating extends Component {
   constructor() {
     super();
     this.state = {
       likes: 0,
       dislikes: 0,
       totalRatings: 0,
       handleLike: () => {
         this.setState((prevState) => ({
           likes: prevState.likes + 1,
           totalRatings: prevState.totalRatings + 1
         }));
       },
       handleDislike: () => {
         this.setState((prevState) => ({
           dislikes: prevState.dislikes + 1,
           totalRatings: prevState.totalRatings + 1
         }));
       }
     };
   }
   render() {
     return (
       <>
         <h1>Évaluation du Contenu Textuel</h1>
         <div className='content-rating'>
           <p>Texte</p>
           <div className='rating-buttons'>
             <button className="like-button" onClick={this.state.handleLike}>
               J'aime ({this.state.likes})
             </button>
             <button className="dislike-button" onClick={this.state.handleDislike}>
               Je n'aime pas ({this.state.dislikes})
             </button>
           </div>
           <p>Total des évaluations : {this.state.totalRatings}</p>
         </div>
       </>
     );
   }
 }
 export default ContentRating;